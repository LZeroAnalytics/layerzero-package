use aiken/builtin
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
    _: OutputReference,
    _: Transaction,
  ) {
    case redeemer {
      SetConfigUln(_) -> true
      CommitVerification(_) -> true
      Verify(_) -> true
    }
  }

  else(_) {
    fail
  }
}
