use aiken/builtin

use LayerZero/Types
use LayerZero/Codec

pub type ReceiveDatum {
  ReceiveDatum {
    local_eid: Types.Eid
  }
}

pub type ReceiveRedeemer {
  SetConfigUln {
    oapp: Types.Address32,
    src_eid: Types.Eid,
    cfg: Types.UlnConfig,
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

pub fn validator(d: ReceiveDatum, r: ReceiveRedeemer, ctx: builtin.ScriptContext) -> Bool {
  builtin.trace("uln302_receive:dispatch")
  case r {
    SetConfigUln { .. } -> true
    CommitVerification { .. } -> true
    Verify { .. } -> true
  }
}
