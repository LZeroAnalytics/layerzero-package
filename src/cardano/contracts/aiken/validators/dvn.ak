use aiken/collection/list
use aiken/builtin
use cardano/transaction.{Datum, Output, OutputReference, Transaction}

use layerzero/types
use layerzero/dvn_helpers

pub type DvnDatum {
  DvnDatum {
    vid: Int,
    quorum: Int,
  }
}

pub type ExecuteParam {
  ExecuteParam {
    vid: Int,
    header_hash: ByteArray,
    payload_hash: ByteArray,
    signer_count: Int,
  }
}

pub type AssignJobParam {
  AssignJobParam {
    dst_eid: types.Eid,
    confirmations: Int,
    sender: types.Address32,
  }
}

pub type DvnRedeemer {
  SetSigner {
    signer: types.Address32,
    active: Bool,
  }
  SetQuorum {
    quorum: Int,
  }
  AssignJob {
    param: AssignJobParam,
    options: ByteArray,
  }
  Execute {
    params: List<ExecuteParam>,
  }
}

fn parse_attestation(d: Data) -> Option<(ByteArray, ByteArray, Int)> {
  let is_constr = builtin.choose_data(d, True, False, False, False, False)
  if is_constr {
    let pr = builtin.un_constr_data(d)
    let _idx = pr.1st
    let fs = pr.2nd
    let f0 = builtin.head_list(fs)
    let fs1 = builtin.tail_list(fs)
    let f1 = builtin.head_list(fs1)
    let fs2 = builtin.tail_list(fs1)
    let f2 = builtin.head_list(fs2)
    let hh = builtin.un_b_data(f0)
    let ph = builtin.un_b_data(f1)
    let sc = builtin.un_i_data(f2)
    Some((hh, ph, sc))
  } else {
    None
  }
}

fn has_attestation_output(outputs: List<Output>, hh: ByteArray, ph: ByteArray, min_signers: Int) -> Bool {
  outputs
    |> list.any(fn(o) {
      when o.datum is {
        Datum.InlineDatum(d) -> {
          when parse_attestation(d) is {
            Some((ah, ap, sc)) ->
              ah == hh && ap == ph && dvn_helpers.quorum_satisfied(sc, min_signers)
            None -> False
          }
        }
        _ -> False
      }
    })
}

validator dvn {
  spend(
    datum: Option<DvnDatum>,
    redeemer: DvnRedeemer,
    _0: OutputReference,
    tx: Transaction,
  ) {
    when redeemer is {
      SetSigner { signer: _, active: _ } -> True
      SetQuorum { quorum: _ } -> True
      AssignJob { param: _, options: _ } -> True
      Execute { params: ps } -> {
        when datum is {
          Some(DvnDatum { vid: _, quorum: q }) -> {
            let ok = ps
              |> list.any(fn(p) {
                let ExecuteParam { vid: _, header_hash: hdrh, payload_hash: plh, signer_count: sc } = p
                dvn_helpers.quorum_satisfied(sc, q) && has_attestation_output(tx.outputs, hdrh, plh, q)
              })
            ok
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
