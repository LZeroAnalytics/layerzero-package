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

test executor_commit_and_execute_accepts_with_empty_native_drops() {
  let datum = Some(executor.ExecutorDatum { local_eid: types.Eid(200) })
  let redeemer = executor.ExecutorRedeemer.CommitAndExecute {
    receive_lib: #"",
    lz_receive_param: mk_lz_receive_param(),
    native_drops: [],
  }
  let tx = transaction.placeholder

  expect executor.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: tx.id, output_index: 0 },
    tx
  ) == True
}

test executor_commit_and_execute_accepts_with_some_native_drops() {
  let datum = Some(executor.ExecutorDatum { local_eid: types.Eid(200) })
  let drops: List<executor.NativeDropParam> = [
    executor.NativeDropParam { receiver: types.Address32(bytearray.new(32)), amount: 10 },
    executor.NativeDropParam { receiver: types.Address32(bytearray.new(32)), amount: 20 },
  ]
  let redeemer = executor.ExecutorRedeemer.CommitAndExecute {
    receive_lib: #"cafebabe",
    lz_receive_param: mk_lz_receive_param(),
    native_drops: drops,
  }
  let tx =
    transaction.Transaction { ..transaction.placeholder, outputs: [mk_out(30)] }

  expect executor.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: tx.id, output_index: 0 },
    tx
  ) == True
}

test executor_commit_and_execute_rejects_when_insufficient_lovelace_for_drops() {
  let datum = Some(executor.ExecutorDatum { local_eid: types.Eid(200) })
  let drops: List<executor.NativeDropParam> = [
    executor.NativeDropParam { receiver: types.Address32(bytearray.new(32)), amount: 15 },
    executor.NativeDropParam { receiver: types.Address32(bytearray.new(32)), amount: 10 },
  ]
  let redeemer = executor.ExecutorRedeemer.CommitAndExecute {
    receive_lib: #"deadbeef",
    lz_receive_param: mk_lz_receive_param(),
    native_drops: drops,
  }
  let tx =
    transaction.Transaction { ..transaction.placeholder, outputs: [mk_out(20)] }

  expect executor.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: tx.id, output_index: 0 },
    tx
  ) == False
}
