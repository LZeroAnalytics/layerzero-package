use aiken/builtin
use aiken/list

use layerzero/types
use layerzero/codec

pub type EndpointDatum {
  EndpointDatum {
    local_eid: types.Eid
  }
}

pub type ChannelDatum {
  ChannelDatum {
    origin: types.Origin,
    receiver: types.Address20,
    lazy_inbound_nonce: types.Nonce,
    executed: Bool,
  }
}

pub type EndpointRedeemer {
  SetConfig {
    oapp: types.Address32,
    dst_eid: types.Eid,
    config_type: Int,
    config: ByteArray,
  }
  Verify {
    origin: types.Origin,
    receiver: types.Address20,
    payload_hash: ByteArray,
  }
  LzReceive {
    origin: types.Origin,
    receiver: types.Address20,
    guid: types.Guid,
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
