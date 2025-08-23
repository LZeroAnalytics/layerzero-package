use cardano/transaction.{OutputReference, Transaction}

use layerzero/types
use layerzero/endpoint_helpers

pub type EndpointDatum {
  Global {
    local_eid: types.Eid
  }
  Channel {
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

validator endpoint {
  spend(
    datum: Option<EndpointDatum>,
    redeemer: EndpointRedeemer,
    _0: OutputReference,
    _1: Transaction,
  ) {
    when redeemer is {
      SetConfig { oapp: _, dst_eid: _, config_type: _, config: _ } -> True
      Verify { origin: og, receiver: rcvr, payload_hash: _ } -> {
        when datum is {
          Some(Channel {
            origin: ch_og,
            receiver: ch_rcvr,
            lazy_inbound_nonce: ch_nonce,
            executed: _,
          }) -> {
            let types.Origin { src_eid: _, sender: _, nonce: in_nonce } = og
            ch_rcvr == rcvr && endpoint_helpers.nonce_next_ok(ch_nonce, in_nonce)
          }
          _ -> False
        }
      }
      LzReceive { origin: og, receiver: rcvr, guid: _, message: _, extra_data: _ } -> {
        when datum is {
          Some(Channel {
            origin: ch_og,
            receiver: ch_rcvr,
            lazy_inbound_nonce: ch_nonce,
            executed: True,
          }) -> {
            let types.Origin { src_eid: _, sender: _, nonce: in_nonce } = og
            ch_rcvr == rcvr && endpoint_helpers.nonce_next_ok(ch_nonce, in_nonce)
          }
          _ -> False
        }
      }
    }
  }

  else(_) {
    fail
  }
}
