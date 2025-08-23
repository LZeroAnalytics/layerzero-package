use aiken/builtin
use aiken/collection/list
use aiken/primitive/bytearray
use cardano/transaction.{Datum, Output, OutputReference, Transaction}
use cardano/assets

use layerzero/types

pub type SendDatum {
  SendDatum {
    oapp: types.Address32,
    dst_eid: types.Eid,
    executor_cfg: types.ExecutorConfig,
    uln_cfg: types.UlnConfig,
    executor_fee_addr: types.Address32,
    dvn_fee_addr: types.Address32,
  }
}

pub type SendRedeemer {
  SetConfigExec {
    oapp: types.Address32,
    dst_eid: types.Eid,
    cfg: types.ExecutorConfig,
  }
  SetConfigUln {
    oapp: types.Address32,
    dst_eid: types.Eid,
    cfg: types.UlnConfig,
  }
  Send {
    options: List<types.WorkerOption>,
  }
}

fn count_fee_recipients(outputs: List<Output>) -> Int {
  list.foldr(
    outputs,
    0,
    fn(o, acc) {
      let lov = assets.lovelace_of(o.value)
      acc + if lov > 0 { 1 } else { 0 }
    },
  )
}
 
fn parse_outbound(d: Data) -> Option<(ByteArray, ByteArray, Int)> {
  let is_constr = builtin.choose_data(d, True, False, False, False, False)
  if is_constr {
    let pr = builtin.un_constr_data(d)
    let fs = pr.2nd
    let f0 = builtin.head_list(fs)
    let fs1 = builtin.tail_list(fs)
    let f1 = builtin.head_list(fs1)
    let fs2 = builtin.tail_list(fs1)
    let f2 = builtin.head_list(fs2)
    let header = builtin.un_b_data(f0)
    let payload = builtin.un_b_data(f1)
    let opts_len = builtin.un_i_data(f2)
    Some((header, payload, opts_len))
  } else {
    None
  }
}

fn has_valid_outbound(outputs: List<Output>, expected_opts_len: Int) -> Bool {
  outputs
    |> list.any(fn(o) {
      when o.datum is {
        Datum.InlineDatum(d) -> {
          when parse_outbound(d) is {
            Some((hdr, _pl, ol)) -> bytearray.length(hdr) == 81 && ol == expected_opts_len
            None -> False
          }
        }
        _ -> False
      }
    })
}

validator uln302_send {
  spend(
    datum: Option<SendDatum>,
    redeemer: SendRedeemer,
    _0: OutputReference,
    tx: Transaction,
  ) {
    when redeemer is {
      SetConfigExec { oapp: _, dst_eid: _, cfg: _ } -> True
      SetConfigUln { oapp: _, dst_eid: _, cfg: _ } -> True
      Send { options: opts } -> {
        when datum is {
          Some(SendDatum { oapp: _, dst_eid: _, executor_fee_addr: _, dvn_fee_addr: _, executor_cfg: _, uln_cfg: _ }) -> {
            has_valid_outbound(tx.outputs, list.length(opts)) &&
            count_fee_recipients(tx.outputs) >= 2
          }
          None -> False
        }
      }
    }
  }

  else(_) {
    fail
  }
}
