use aiken/builtin
use cardano/address
use cardano/assets
use cardano/transaction

use layerzero/types
use layerzero/codec
use layerzero/validators/uln302_receive

test uln302_verify_accepts_with_matching_attestation() {
  let local_eid = types.Eid(200)
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(1),
    src_eid: types.Eid(100),
    sender: types.Address32(bytearray.new(32)),
    dst_eid: local_eid,
    receiver_b20: types.Address20(bytearray.new(20)),
  }
  let ph = codec.encode_header_v1(header)
  let hh = codec.header_hash_v1(ph)

  let guid = types.Guid(bytearray.from_hex("00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"))
  let msg = bytearray.from_utf8("hi")
  let plh = codec.payload_hash(guid, msg)

  let att: Data =
    builtin.constr_data(
      0,
      builtin.list_data([builtin.b_data(hh), builtin.b_data(plh), builtin.i_data(3)]),
    )

  let out = transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.zero,
    datum: transaction.Datum.InlineDatum(att),
    reference_script: None,
  }

  let tx = transaction.Transaction {
    ..transaction.placeholder,
    outputs: [out],
  }

  let datum = Some(uln302_receive.ReceiveDatum { local_eid: local_eid })
  let redeemer = uln302_receive.ReceiveRedeemer.Verify {
    packet_header: ph,
    payload_hash: plh,
    confirmations: 0,
  }

  expect uln302_receive.spend(datum, redeemer, transaction.OutputReference { transaction_id: transaction.placeholder.id, output_index: 0 }, tx) == True
}

test uln302_verify_rejects_with_mismatched_attestation() {
  let local_eid = types.Eid(200)
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(2),
    src_eid: types.Eid(101),
    sender: types.Address32(bytearray.new(32)),
    dst_eid: local_eid,
    receiver_b20: types.Address20(bytearray.new(20)),
  }
  let ph = codec.encode_header_v1(header)
  let hh = codec.header_hash_v1(ph)

  let guid_ok = types.Guid(bytearray.from_hex("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"))
  let msg_ok = bytearray.from_utf8("ok")
  let plh_ok = codec.payload_hash(guid_ok, msg_ok)

  let guid_bad = types.Guid(bytearray.from_hex("bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"))
  let msg_bad = bytearray.from_utf8("bad")
  let plh_bad = codec.payload_hash(guid_bad, msg_bad)

  let att_wrong: Data =
    builtin.constr_data(
      0,
      builtin.list_data([builtin.b_data(hh), builtin.b_data(plh_bad), builtin.i_data(1)]),
    )

  let out = transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.zero,
    datum: transaction.Datum.InlineDatum(att_wrong),
    reference_script: None,
  }

  let tx = transaction.Transaction {
    ..transaction.placeholder,
    outputs: [out],
  }

  let datum = Some(uln302_receive.ReceiveDatum { local_eid: local_eid })
  let redeemer = uln302_receive.ReceiveRedeemer.Verify {
    packet_header: ph,
    payload_hash: plh_ok,
    confirmations: 0,
  }

  expect uln302_receive.spend(datum, redeemer, transaction.OutputReference { transaction_id: transaction.placeholder.id, output_index: 0 }, tx) == False
}
