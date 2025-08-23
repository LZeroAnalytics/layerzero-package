use aiken/collection/list
use aiken/builtin
use cardano/transaction.{Datum, Output, OutputReference, Transaction}

use layerzero/types
use layerzero/codec

pub type ReceiveDatum {
  ReceiveDatum {
    local_eid: types.Eid
  }
}

pub type ReceiveRedeemer {
  SetConfigUln {
    oapp: types.Address32,
    src_eid: types.Eid,
    cfg: types.UlnConfig,
  }
  CommitVerification {
    packet_header: ByteArray,
    payload_hash: ByteArray,
  }
  Verify {
    packet_header: ByteArray,
    payload_hash: ByteArray,
    confirmations: Int,
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

fn has_matching_attestation(outputs: List<Output>, hh: ByteArray, ph: ByteArray) -> Bool {
  outputs
    |> list.any(fn(o) {
      when o.datum is {
        Datum.InlineDatum(d) -> {
          when parse_attestation(d) is {
            Some((ah, ap, _)) -> ah == hh && ap == ph
            None -> False
          }
        }
        _ -> False
      }
    })
}

fn parse_endpoint_channel(d: Data) -> Option<(types.Address20, types.Nonce, Bool)> {
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
      let r_pr = builtin.un_constr_data(f_receiver)
      let r_b = builtin.un_b_data(builtin.head_list(r_pr.2nd))
      let n_pr = builtin.un_constr_data(f_nonce)
      let n_i = builtin.un_i_data(builtin.head_list(n_pr.2nd))
      let e_pr = builtin.un_constr_data(f_executed)
      let executed = e_pr.1st == 1
      Some((types.Address20(r_b), types.Nonce(n_i), executed))
    } else {
      None
    }
  } else {
    None
  }
}

fn has_matching_endpoint_verify_output(
  outputs: List<Output>,
  receiver: types.Address20,
  prev_nonce: types.Nonce,
) -> Bool {
  outputs
    |> list.any(fn(o) {
      when o.datum is {
        Datum.InlineDatum(d) -> {
          when parse_endpoint_channel(d) is {
            Some((rcvr, lazy_nonce, executed)) -> rcvr == receiver && executed && lazy_nonce == prev_nonce
            None -> False
          }
        }
        _ -> False
      }
    })
}

validator uln302_receive {
  spend(
    datum: Option<ReceiveDatum>,
    redeemer: ReceiveRedeemer,
    _0: OutputReference,
    tx: Transaction,
  ) {
    when redeemer is {
      SetConfigUln { oapp: _, src_eid: _, cfg: _ } -> True
      CommitVerification { packet_header: ph, payload_hash: _ } -> {
        when datum is {
          Some(ReceiveDatum { local_eid: le }) -> codec.assert_header_v1(ph, le)
          None -> False
        }
      }
      Verify { packet_header: ph, payload_hash: plh, confirmations: _ } -> {
        when datum is {
          Some(ReceiveDatum { local_eid: le }) -> {
            let ok_hdr = codec.assert_header_v1(ph, le)
            let hh = codec.header_hash_v1(ph)
            let ok_att = has_matching_attestation(tx.outputs, hh, plh)
            let types.Nonce(in_i) = codec.header_nonce(ph)
            let rcvr = codec.header_receiver_b20(ph)
            let prev_nonce = types.Nonce(in_i - 1)
            let ok_ep = has_matching_endpoint_verify_output(tx.outputs, rcvr, prev_nonce)
            ok_hdr && ok_att && ok_ep
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
