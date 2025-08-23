use aiken/collection/list
use aiken/builtin
use cardano/transaction.{Datum, Output, OutputReference, Transaction, Input}
use cardano/assets
use aiken/crypto.{VerificationKeyHash}
use cardano/address.{Credential}

use layerzero/types

pub type ExecutorDatum {
  ExecutorDatum {
    local_eid: types.Eid,
    executor_fee_vkh: VerificationKeyHash
  }
}

pub type NativeDropParam {
  NativeDropParam {
    receiver: types.Address32,
    amount: Int,
  }
}

pub type LzReceiveParam {
  LzReceiveParam {
    origin: types.Origin,
    receiver: types.Address32,
    guid: types.Guid,
    message: ByteArray,
    extra_data: ByteArray,
    gas: Int,
    value: Int,
  }
}

pub type ExecutorRedeemer {
  CommitAndExecute {
    receive_lib: ByteArray,
    lz_receive_param: LzReceiveParam,
    native_drops: List<NativeDropParam>,
  }
}

fn parse_endpoint_channel(d: Data) -> Option<(types.Origin, types.Address20, types.Nonce, Bool)> {
  let is_constr = builtin.choose_data(d, True, False, False, False, False)
  if is_constr {
    let pr = builtin.un_constr_data(d)
    let tag = pr.1st
    if tag == 1 {
      let fs = pr.2nd
      let f_origin = builtin.head_list(fs)
      let fs1 = builtin.tail_list(fs)
      let f_receiver = builtin.head_list(fs1)
      let fs2 = builtin.tail_list(fs1)
      let f_nonce = builtin.head_list(fs2)
      let fs3 = builtin.tail_list(fs2)
      let f_executed = builtin.head_list(fs3)

      let og_pr = builtin.un_constr_data(f_origin)
      let og_fs = og_pr.2nd
      let f_eid = builtin.head_list(og_fs)
      let og_fs1 = builtin.tail_list(og_fs)
      let f_sender = builtin.head_list(og_fs1)
      let og_fs2 = builtin.tail_list(og_fs1)
      let f_og_nonce = builtin.head_list(og_fs2)

      let eid_pr = builtin.un_constr_data(f_eid)
      let eid_i = builtin.un_i_data(builtin.head_list(eid_pr.2nd))

      let snd_pr = builtin.un_constr_data(f_sender)
      let snd_b = builtin.un_b_data(builtin.head_list(snd_pr.2nd))

      let on_pr = builtin.un_constr_data(f_og_nonce)
      let on_i = builtin.un_i_data(builtin.head_list(on_pr.2nd))

      let rc_pr = builtin.un_constr_data(f_receiver)
      let rc_b = builtin.un_b_data(builtin.head_list(rc_pr.2nd))

      let ln_pr = builtin.un_constr_data(f_nonce)
      let ln_i = builtin.un_i_data(builtin.head_list(ln_pr.2nd))

      let ex_pr = builtin.un_constr_data(f_executed)
      let executed = ex_pr.1st == 1

      Some((
        types.Origin { src_eid: types.Eid(eid_i), sender: types.Address32(snd_b), nonce: types.Nonce(on_i) },
        types.Address20(rc_b),
        types.Nonce(ln_i),
        executed
      ))
    } else {
      None
    }
  } else {
    None
  }
}
fn has_endpoint_prev_input(prev_nonce: types.Nonce, executed_flag: Bool, inputs: List<Input>) -> Bool {
  inputs
    |> list.any(fn(i) {
      when i.output.datum is {
        Datum.InlineDatum(d) -> {
          when parse_endpoint_channel(d) is {
            Some((_og, _rc, lazy_nonce, executed)) -> lazy_nonce == prev_nonce && executed == executed_flag
            None -> False
          }
        }
        _ -> False
      }
    })
}

 



fn has_endpoint_curr_output(curr_nonce: types.Nonce, executed_flag: Bool, outputs: List<Output>) -> Bool {
  outputs
    |> list.any(fn(o) {
      when o.datum is {
        Datum.InlineDatum(d) -> {
          when parse_endpoint_channel(d) is {
            Some((_og, _rc, lazy_nonce, executed)) -> lazy_nonce == curr_nonce && executed == executed_flag
            None -> False
          }
        }
        _ -> False
      }
    })
}
fn sum_native_drops(ds: List<NativeDropParam>) -> Int {
  list.foldr(ds, 0, fn(d, acc) { d.amount + acc })
}

fn total_outputs_lovelace(tx: Transaction) -> Int {
  list.foldr(
    tx.outputs,
    0,
    fn(o, acc) { assets.lovelace_of(o.value) + acc },
  )
}

fn has_executor_fee_output(outputs: List<Output>, vkh: VerificationKeyHash) -> Bool {
  outputs
    |> list.any(fn(o) {
      when o.address.payment_credential is {
        Credential.VerificationKey(k) -> k == vkh && assets.lovelace_of(o.value) > 0
        _ -> False
      }
    })
}

validator executor {
  spend(
    datum: Option<ExecutorDatum>,
    redeemer: ExecutorRedeemer,
    _0: OutputReference,
    tx: Transaction,
  ) {
    let CommitAndExecute { receive_lib: _, lz_receive_param: lp, native_drops: drops } = redeemer
    when datum is {
      Some(ExecutorDatum { local_eid: _, executor_fee_vkh: fee_vkh }) -> {
        let need = sum_native_drops(drops)
        let have = total_outputs_lovelace(tx)
        let types.Origin { nonce: og_nonce, .. } = lp.origin
        let types.Nonce(n_i) = og_nonce
        let prev = types.Nonce(n_i - 1)
        let ok_prev_in = has_endpoint_prev_input(prev, True, tx.inputs)
        let ok_curr_out = has_endpoint_curr_output(og_nonce, False, tx.outputs)
        let ok_fee = has_executor_fee_output(tx.outputs, fee_vkh)
        ok_prev_in && ok_curr_out && ok_fee && have >= need && need >= 0
      }
      None -> False
    }
  }

  else(_) {
    fail
  }
}
