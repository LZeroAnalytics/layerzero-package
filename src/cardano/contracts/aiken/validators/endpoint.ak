use aiken/builtin
use aiken/list

use LayerZero/Types
use LayerZero/Codec

pub type EndpointDatum {
  EndpointDatum {
    local_eid: Types.Eid
  }
}

pub type ChannelDatum {
  ChannelDatum {
    origin: Types.Origin,
    receiver: Types.Address20,
    lazy_inbound_nonce: Types.Nonce,
    executed: Bool,
  }
}

pub type EndpointRedeemer {
  SetConfig {
    oapp: Types.Address32,
    dst_eid: Types.Eid,
    config_type: Int,
    config: ByteArray,
  }
  Verify {
    origin: Types.Origin,
    receiver: Types.Address20,
    payload_hash: ByteArray,
  }
  LzReceive {
    origin: Types.Origin,
    receiver: Types.Address20,
    guid: Types.Guid,
    message: ByteArray,
    extra_data: ByteArray,
  }
}

pub fn validator(d: EndpointDatum, r: EndpointRedeemer, ctx: builtin.ScriptContext) -> Bool {
  builtin.trace("endpoint:dispatch")
  case r {
    SetConfig { .. } -> true
    Verify { .. } -> true
    LzReceive { .. } -> true
  }
}
