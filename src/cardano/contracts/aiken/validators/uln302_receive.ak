use cardano/transaction.{OutputReference, Transaction}

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

validator uln302_receive {
  spend(
    datum: Option<ReceiveDatum>,
    redeemer: ReceiveRedeemer,
    _0: OutputReference,
    _1: Transaction,
  ) {
    when redeemer is {
      SetConfigUln { oapp: _, src_eid: _, cfg: _ } -> True
      CommitVerification { packet_header: ph, payload_hash: _ } -> {
        // For now only assert header against local_eid in datum if present
        when datum is {
          Some(ReceiveDatum { local_eid: le }) -> codec.assert_header_v1(ph, le)
          None -> False
        }
      }
      Verify { packet_header: ph, payload_hash: _, confirmations: _ } -> {
        when datum is {
          Some(ReceiveDatum { local_eid: le }) -> codec.assert_header_v1(ph, le)
          None -> False
        }
      }
    }
  }

  else(_) {
    fail
  }
}
