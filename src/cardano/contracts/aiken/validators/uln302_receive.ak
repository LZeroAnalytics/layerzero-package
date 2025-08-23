use aiken/builtin

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
  fn spend(d: ReceiveDatum, r: ReceiveRedeemer, ctx: builtin.ScriptContext) -> Bool {
    builtin.trace("uln302_receive:dispatch")
    case r {
      SetConfigUln { .. } -> true
      CommitVerification { .. } -> true
      Verify { .. } -> true
    }
  }
}
