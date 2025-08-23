use aiken/collection/list
use aiken/builtin
use cardano/transaction.{Datum, Output, OutputReference, Transaction}

use layerzero/types
use layerzero/dvn_helpers

pub type DvnDatum {
  DvnDatum {
    vid: Int,
    quorum: Int,
    signers: List<types.Address32>,
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
  SetSignerSet {
    signers: List<types.Address32>,
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

fn parse_sigs(d: Data) -> Option<(ByteArray, ByteArray, List<ByteArray>, List<types.Address32>)> {
  let is_constr = builtin.choose_data(d, True, False, False, False, False)
  if is_constr {
    let pr = builtin.un_constr_data(d)
    let fs = pr.2nd
    let f0 = builtin.head_list(fs)
    let fs1 = builtin.tail_list(fs)
    let f1 = builtin.head_list(fs1)
    let fs2 = builtin.tail_list(fs1)
    let f2 = builtin.head_list(fs2)
    let fs3 = builtin.tail_list(fs2)
    let f3 = builtin.head_list(fs3)
    let hh = builtin.un_b_data(f0)
    let ph = builtin.un_b_data(f1)
    let sigs_data = builtin.un_list_data(f2)
    let pubs_data = builtin.un_list_data(f3)
    let sigs = list.map(sigs_data, fn(x) { builtin.un_b_data(x) })
    let pubs = list.map(pubs_data, fn(x) {
      let prx = builtin.un_constr_data(x)
      let b = builtin.un_b_data(builtin.head_list(prx.2nd))
      types.Address32(b)
    })
    Some((hh, ph, sigs, pubs))
  } else {
    None
  }
}
 
fn find_attestation(outputs: List<Output>, hh: ByteArray, ph: ByteArray) -> Bool {
  outputs
    |> list.any(fn(o) {
      when o.datum is {
        Datum.InlineDatum(d) -> {
          when parse_attestation(d) is {
            Some((ah, ap, sc)) -> ah == hh && ap == ph && sc >= 0
            None -> False
          }
        }
        _ -> False
      }
    })
}

fn find_sigs(outputs: List<Output>, hh: ByteArray, ph: ByteArray) -> Option<(List<ByteArray>, List<types.Address32>)> {
  list.foldr(
    outputs,
    None,
    fn(o, acc) {
      when acc is {
        Some(_) -> acc
        None -> {
          when o.datum is {
            Datum.InlineDatum(d) -> {
              when parse_sigs(d) is {
                Some((ah, ap, sigs, pubs)) -> if ah == hh && ap == ph { Some((sigs, pubs)) } else { None }
                None -> None
              }
            }
            _ -> None
          }
        }
      }
    },
  )
}

validator dvn {
  spend(
    datum: Option<DvnDatum>,
    redeemer: DvnRedeemer,
    _0: OutputReference,
    tx: Transaction,
  ) {
    when redeemer is {
      SetSignerSet { signers: _ } -> True
      SetQuorum { quorum: _ } -> True
      AssignJob { param: _, options: _ } -> True
      Execute { params: ps } -> {
        when datum is {
          Some(DvnDatum { vid: _, quorum: q, signers: ss }) -> {
            let ok = ps
              |> list.any(fn(p) {
                let ExecuteParam { vid: _, header_hash: hdrh, payload_hash: plh, signer_count: _ } = p
                let has_att = find_attestation(tx.outputs, hdrh, plh)
                when find_sigs(tx.outputs, hdrh, plh) is {
                  Some((sigs, pubs)) -> {
                    let msg = dvn_helpers.attestation_message(hdrh, plh)
                    let within_set = dvn_helpers.signers_within_set(pubs, ss)
                    let unique = dvn_helpers.unique_signers(pubs)
                    let ok_ms = dvn_helpers.verify_multisig(msg, pubs, sigs, q)
                    has_att && within_set && unique && ok_ms
                  }
                  None -> False
                }
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
