use aiken/builtin
use cardano/transaction
use cardano/address
use cardano/assets

use layerzero/types
use layerzero/validators/executor

fn mk_lz_receive_param() -> executor.LzReceiveParam {
  executor.LzReceiveParam {
    origin: types.Origin {
      src_eid: types.Eid(100),
      sender: types.Address32(bytearray.new(32)),
      nonce: types.Nonce(1),
    },
    receiver: types.Address32(bytearray.new(32)),
    guid: types.Guid(bytearray.new(32)),
    message: bytearray.from_utf8("hello"),
    extra_data: bytearray.new(0),
    gas: 0,
    value: 0,
  }
}

fn mk_out(lovelace: Int) -> transaction.Output {
  transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.from_lovelace(lovelace),
    datum: transaction.Datum.NoDatum,
    reference_script: None,
  }
}

fn mk_executor_fee_out(vkh: ByteArray) -> transaction.Output {
  transaction.Output {
    address: address.from_verification_key(vkh),
    value: assets.from_lovelace(1),
    datum: transaction.Datum.NoDatum,
    reference_script: None,
  }
}

fn mk_endpoint_channel_input(prev_nonce: Int) -> transaction.Input {
  let eid_d = builtin.constr_data(0, builtin.list_data([builtin.i_data(100)]))
  let sender_d = builtin.constr_data(0, builtin.list_data([builtin.b_data(bytearray.new(32))]))
  let og_nonce_d = builtin.constr_data(0, builtin.list_data([builtin.i_data(prev_nonce)]))
  let origin_d = builtin.constr_data(0, builtin.list_data([eid_d, sender_d, og_nonce_d]))
  let recv_d = builtin.constr_data(0, builtin.list_data([builtin.b_data(bytearray.new(20))]))
  let lazy_nonce_d = builtin.constr_data(0, builtin.list_data([builtin.i_data(prev_nonce)]))
  let executed_true_d = builtin.constr_data(1, [])
  let channel_d = builtin.constr_data(1, builtin.list_data([origin_d, recv_d, lazy_nonce_d, executed_true_d]))
  let out = transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.zero,
    datum: transaction.Datum.InlineDatum(channel_d),
    reference_script: None,
  }
  transaction.Input { output_reference: transaction.placeholder.id |> fn(id) { transaction.OutputReference { transaction_id: id, output_index: 0 } }(transaction.placeholder.id), output: out }
}

fn mk_endpoint_channel_output(curr_nonce: Int) -> transaction.Output {
  let eid_d = builtin.constr_data(0, builtin.list_data([builtin.i_data(100)]))
  let sender_d = builtin.constr_data(0, builtin.list_data([builtin.b_data(bytearray.new(32))]))
  let og_nonce_d = builtin.constr_data(0, builtin.list_data([builtin.i_data(curr_nonce)]))
  let origin_d = builtin.constr_data(0, builtin.list_data([eid_d, sender_d, og_nonce_d]))
  let recv_d = builtin.constr_data(0, builtin.list_data([builtin.b_data(bytearray.new(20))]))
  let lazy_nonce_d = builtin.constr_data(0, builtin.list_data([builtin.i_data(curr_nonce)]))
  let executed_false_d = builtin.constr_data(0, [])
  let channel_d = builtin.constr_data(1, builtin.list_data([origin_d, recv_d, lazy_nonce_d, executed_false_d]))
  transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.zero,
    datum: transaction.Datum.InlineDatum(channel_d),
    reference_script: None,
  }
}

test executor_commit_and_execute_accepts_with_empty_native_drops() {
  let fee_vkh = #"aa"
  let datum = Some(executor.ExecutorDatum { local_eid: types.Eid(200), executor_fee_vkh: fee_vkh })
  let redeemer = executor.ExecutorRedeemer.CommitAndExecute {
    receive_lib: #"",
    lz_receive_param: mk_lz_receive_param(),
    native_drops: [],
  }
  let ep_in = mk_endpoint_channel_input(1 - 1)
  let ep_out = mk_endpoint_channel_output(1)
  let tx = transaction.Transaction { ..transaction.placeholder, inputs: [ep_in], outputs: [mk_executor_fee_out(fee_vkh), ep_out] }
  expect executor.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: tx.id, output_index: 0 },
    tx
  ) == True
}

test executor_commit_and_execute_accepts_with_some_native_drops() {
  let fee_vkh = #"bb"
  let datum = Some(executor.ExecutorDatum { local_eid: types.Eid(200), executor_fee_vkh: fee_vkh })
  let drops: List<executor.NativeDropParam> = [
    executor.NativeDropParam { receiver: types.Address32(bytearray.new(32)), amount: 10 },
    executor.NativeDropParam { receiver: types.Address32(bytearray.new(32)), amount: 20 },
  ]
  let redeemer = executor.ExecutorRedeemer.CommitAndExecute {
    receive_lib: #"cafebabe",
    lz_receive_param: mk_lz_receive_param(),
    native_drops: drops,
  }
  let ep_in = mk_endpoint_channel_input(1 - 1)
  let ep_out = mk_endpoint_channel_output(1)
  let tx =
    transaction.Transaction { ..transaction.placeholder, inputs: [ep_in], outputs: [mk_out(30), mk_executor_fee_out(fee_vkh), ep_out] }

  expect executor.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: tx.id, output_index: 0 },
    tx
  ) == True
}

test executor_commit_and_execute_rejects_when_insufficient_lovelace_for_drops() {
  let fee_vkh = #"cc"
  let datum = Some(executor.ExecutorDatum { local_eid: types.Eid(200), executor_fee_vkh: fee_vkh })
  let drops: List<executor.NativeDropParam> = [
    executor.NativeDropParam { receiver: types.Address32(bytearray.new(32)), amount: 15 },
    executor.NativeDropParam { receiver: types.Address32(bytearray.new(32)), amount: 10 },
  ]
  let redeemer = executor.ExecutorRedeemer.CommitAndExecute {
    receive_lib: #"deadbeef",
    lz_receive_param: mk_lz_receive_param(),
    native_drops: drops,
  }
  let ep_in = mk_endpoint_channel_input(1 - 1)
  let ep_out = mk_endpoint_channel_output(1)
  let tx =
    transaction.Transaction { ..transaction.placeholder, inputs: [ep_in], outputs: [mk_out(20), mk_executor_fee_out(fee_vkh), ep_out] }

  expect executor.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: tx.id, output_index: 0 },
    tx
  ) == False
}
