use cardano/transaction

use layerzero/types
use layerzero/validators/endpoint

test endpoint_verify_accepts_when_nonce_monotonic_and_receiver_matches() {
  let ch = endpoint.EndpointDatum.Channel {
    origin: types.Origin {
      src_eid: types.Eid(100),
      sender: types.Address32(bytearray.new(32)),
      nonce: types.Nonce(0),
    },
    receiver: types.Address20(bytearray.new(20)),
    lazy_inbound_nonce: types.Nonce(5),
    executed: False,
  }

  let incoming_origin = types.Origin {
    src_eid: types.Eid(100),
    sender: types.Address32(bytearray.new(32)),
    nonce: types.Nonce(6),
  }

  let redeemer = endpoint.EndpointRedeemer.Verify {
    origin: incoming_origin,
    receiver: types.Address20(bytearray.new(20)),
    payload_hash: bytearray.new(32),
  }

  let datum = Some(ch)
  let tx = transaction.placeholder

  expect endpoint.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: tx.id, output_index: 0 },
    tx
  ) == True
}

test endpoint_verify_rejects_when_nonce_not_monotonic() {
  let ch = endpoint.EndpointDatum.Channel {
    origin: types.Origin {
      src_eid: types.Eid(100),
      sender: types.Address32(bytearray.new(32)),
      nonce: types.Nonce(0),
    },
    receiver: types.Address20(bytearray.new(20)),
    lazy_inbound_nonce: types.Nonce(5),
    executed: False,
  }

  let incoming_origin = types.Origin {
    src_eid: types.Eid(100),
    sender: types.Address32(bytearray.new(32)),
    nonce: types.Nonce(5),
  }

  let redeemer = endpoint.EndpointRedeemer.Verify {
    origin: incoming_origin,
    receiver: types.Address20(bytearray.new(20)),
    payload_hash: bytearray.new(32),
  }

  let datum = Some(ch)
  let tx = transaction.placeholder

  expect endpoint.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: tx.id, output_index: 0 },
    tx
  ) == False
}

test endpoint_lzreceive_requires_executed_true_and_monotonic() {
  let ch = endpoint.EndpointDatum.Channel {
    origin: types.Origin {
      src_eid: types.Eid(100),
      sender: types.Address32(bytearray.new(32)),
      nonce: types.Nonce(0),
    },
    receiver: types.Address20(bytearray.new(20)),
    lazy_inbound_nonce: types.Nonce(7),
    executed: True,
  }

  let incoming_origin = types.Origin {
    src_eid: types.Eid(100),
    sender: types.Address32(bytearray.new(32)),
    nonce: types.Nonce(8),
  }

  let redeemer = endpoint.EndpointRedeemer.LzReceive {
    origin: incoming_origin,
    receiver: types.Address20(bytearray.new(20)),
    guid: types.Guid(bytearray.new(32)),
    message: bytearray.from_utf8("hi"),
    extra_data: bytearray.new(0),
  }

  let datum = Some(ch)
  let tx = transaction.placeholder

  expect endpoint.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: tx.id, output_index: 0 },
    tx
  ) == True
}

test endpoint_lzreceive_rejects_when_executed_false() {
  let ch = endpoint.EndpointDatum.Channel {
    origin: types.Origin {
      src_eid: types.Eid(100),
      sender: types.Address32(bytearray.new(32)),
      nonce: types.Nonce(0),
    },
    receiver: types.Address20(bytearray.new(20)),
    lazy_inbound_nonce: types.Nonce(7),
    executed: False,
  }

  let incoming_origin = types.Origin {
    src_eid: types.Eid(100),
    sender: types.Address32(bytearray.new(32)),
    nonce: types.Nonce(8),
  }

  let redeemer = endpoint.EndpointRedeemer.LzReceive {
    origin: incoming_origin,
    receiver: types.Address20(bytearray.new(20)),
    guid: types.Guid(bytearray.new(32)),
    message: bytearray.from_utf8("hi"),
    extra_data: bytearray.new(0),
  }

  let datum = Some(ch)
  let tx = transaction.placeholder

  expect endpoint.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: tx.id, output_index: 0 },
    tx
  ) == False
}
