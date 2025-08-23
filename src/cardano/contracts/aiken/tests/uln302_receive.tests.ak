use aiken/builtin
use aiken/collection/list
use aiken/primitive/bytearray
use cardano/address
use cardano/assets
use cardano/transaction

use layerzero/types
use layerzero/codec
use layerzero/validators/uln302_receive

fn mk_endpoint_channel_inline(receiver_b20: ByteArray, prev_nonce: Int, origin_nonce: Int) -> transaction.Output {
  let eid_d = builtin.constr_data(0, builtin.list_data([builtin.i_data(100)]))
  let sender_d = builtin.constr_data(0, builtin.list_data([builtin.b_data(bytearray.new(32))]))
  let og_nonce_d = builtin.constr_data(0, builtin.list_data([builtin.i_data(origin_nonce)]))
  let origin_d =
    builtin.constr_data(0, builtin.list_data([eid_d, sender_d, og_nonce_d]))

  let recv_d = builtin.constr_data(0, builtin.list_data([builtin.b_data(receiver_b20)]))
  let lazy_nonce_d = builtin.constr_data(0, builtin.list_data([builtin.i_data(prev_nonce)]))
  let executed_true_d = builtin.constr_data(1, [])

  let channel_d =
    builtin.constr_data(
      1,
      builtin.list_data([origin_d, recv_d, lazy_nonce_d, executed_true_d]),
    )

  transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.zero,
    datum: transaction.Datum.InlineDatum(channel_d),
    reference_script: None,
  }
}

test uln302_verify_accepts_with_matching_attestation_and_endpoint_channel_output() {
  let local_eid = types.Eid(200)
  let receiver_b20 = bytearray.new(20)
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(1),
    src_eid: types.Eid(100),
    sender: types.Address32(bytearray.new(32)),
    dst_eid: local_eid,
    receiver_b20: types.Address20(receiver_b20),
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

  let out_att = transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.zero,
    datum: transaction.Datum.InlineDatum(att),
    reference_script: None,
  }

  let out_ep = mk_endpoint_channel_inline(receiver_b20, 0, 1)

  let tx = transaction.Transaction {
    ..transaction.placeholder,
    outputs: [out_att, out_ep],
  }

  let datum = Some(uln302_receive.ReceiveDatum { local_eid: local_eid, dvn_vid: 1, required_quorum: 1, required_confirmations: 0 })
  let redeemer = uln302_receive.ReceiveRedeemer.Verify {
    packet_header: ph,
    payload_hash: plh,
    confirmations: 0,
  }

  expect uln302_receive.spend(datum, redeemer, transaction.OutputReference { transaction_id: transaction.placeholder.id, output_index: 0 }, tx) == True
}

test uln302_verify_rejects_without_endpoint_channel_output() {
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

  let att_ok: Data =
    builtin.constr_data(
      0,
      builtin.list_data([builtin.b_data(hh), builtin.b_data(plh_ok), builtin.i_data(2)]),
    )

  let out = transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.zero,
    datum: transaction.Datum.InlineDatum(att_ok),
    reference_script: None,
  }

  let tx = transaction.Transaction {
    ..transaction.placeholder,
    outputs: [out],
  }

  let datum = Some(uln302_receive.ReceiveDatum { local_eid: local_eid, dvn_vid: 1, required_quorum: 1, required_confirmations: 0 })
  let redeemer = uln302_receive.ReceiveRedeemer.Verify {
    packet_header: ph,
    payload_hash: plh_ok,
    confirmations: 0,
  }

  expect uln302_receive.spend(datum, redeemer, transaction.OutputReference { transaction_id: transaction.placeholder.id, output_index: 0 }, tx) == False
}
fn mk_sigs_output(hh: ByteArray, ph: ByteArray, sigs: List<ByteArray>, pubs: List<ByteArray>) -> transaction.Output {
  let sigs_list = list.map(sigs, fn(s) { builtin.b_data(s) })
  let pubs_list = list.map(pubs, fn(p) { builtin.constr_data(0, builtin.list_data([ builtin.b_data(p) ])) })
  let d: Data =
    builtin.constr_data(
      1,
      builtin.list_data([ builtin.b_data(hh), builtin.b_data(ph), builtin.list_data(sigs_list), builtin.list_data(pubs_list) ]),
    )
  transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.zero,
    datum: transaction.Datum.InlineDatum(d),
    reference_script: None,
  }
}

fn mk_dvn_ref_input(vid: Int, quorum: Int, signers: List<ByteArray>) -> transaction.Input {
  let signers_list = list.map(signers, fn(p) { builtin.constr_data(0, builtin.list_data([ builtin.b_data(p) ])) })
  let dvn_datum =
    builtin.constr_data(
      0,
      builtin.list_data([
        builtin.i_data(vid),
        builtin.i_data(quorum),
        builtin.list_data(signers_list),
        builtin.b_data(#"00"),
      ]),
    )
  let out = transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.zero,
    datum: transaction.Datum.InlineDatum(dvn_datum),
    reference_script: None,
  }
  transaction.Input { output_reference: transaction.OutputReference { transaction_id: transaction.placeholder.id, output_index: 0 }, output: out }
}

test uln302_verify_accepts_with_dvn_ref_and_empty_sigs_when_quorum_zero() {
  let local_eid = types.Eid(200)
  let receiver_b20 = bytearray.new(20)
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(1),
    src_eid: types.Eid(100),
    sender: types.Address32(bytearray.new(32)),
    dst_eid: local_eid,
    receiver_b20: types.Address20(receiver_b20),
  }
  let ph = codec.encode_header_v1(header)
  let hh = codec.header_hash_v1(ph)

  let guid = types.Guid(bytearray.from_hex("00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"))
  let msg = bytearray.from_utf8("hi")
  let plh = codec.payload_hash(guid, msg)

  let att: Data =
    builtin.constr_data(
      0,
      builtin.list_data([builtin.b_data(hh), builtin.b_data(plh), builtin.i_data(0)]),
    )

  let out_att = transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.zero,
    datum: transaction.Datum.InlineDatum(att),
    reference_script: None,
  }

  let out_sigs = mk_sigs_output(hh, plh, [], [])
  let out_ep = mk_endpoint_channel_inline(receiver_b20, 0, 1)

  let dvn_in = mk_dvn_ref_input(1, 0, [])
  let tx = transaction.Transaction { ..transaction.placeholder, reference_inputs: [dvn_in], outputs: [out_att, out_sigs, out_ep] }

  let datum = Some(uln302_receive.ReceiveDatum { local_eid: local_eid, dvn_vid: 1, required_quorum: 0, required_confirmations: 0 })
  let redeemer = uln302_receive.ReceiveRedeemer.Verify { packet_header: ph, payload_hash: plh, confirmations: 0 }

  expect uln302_receive.spend(datum, redeemer, transaction.OutputReference { transaction_id: transaction.placeholder.id, output_index: 0 }, tx) == True
}

test uln302_verify_rejects_with_duplicate_signers_even_if_quorum_met() {
  let local_eid = types.Eid(200)
  let receiver_b20 = bytearray.new(20)
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(1),
    src_eid: types.Eid(100),
    sender: types.Address32(bytearray.new(32)),
    dst_eid: local_eid,
    receiver_b20: types.Address20(receiver_b20),
  }
  let ph = codec.encode_header_v1(header)
  let hh = codec.header_hash_v1(ph)

  let guid = types.Guid(bytearray.from_hex("00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"))
  let msg = bytearray.from_utf8("hi")
  let plh = codec.payload_hash(guid, msg)

  let att: Data =
    builtin.constr_data(
      0,
      builtin.list_data([builtin.b_data(hh), builtin.b_data(plh), builtin.i_data(2)]),
    )

  let out_att = transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.zero,
    datum: transaction.Datum.InlineDatum(att),
    reference_script: None,
  }

  let pub = bytearray.from_hex("5172F998FC21A893DC69ADBDE3C8A80EAFCF8C40DB0C28845BC7D7C0739DBD7E")
  let sig = bytearray.new(64)

  let out_sigs = mk_sigs_output(hh, plh, [sig, sig], [pub, pub])
  let out_ep = mk_endpoint_channel_inline(receiver_b20, 0, 1)

  let dvn_in = mk_dvn_ref_input(1, 2, [pub])
  let tx = transaction.Transaction { ..transaction.placeholder, reference_inputs: [dvn_in], outputs: [out_att, out_sigs, out_ep] }

  let datum = Some(uln302_receive.ReceiveDatum { local_eid: local_eid, dvn_vid: 1, required_quorum: 2, required_confirmations: 0 })
  let redeemer = uln302_receive.ReceiveRedeemer.Verify { packet_header: ph, payload_hash: plh, confirmations: 0 }

  expect uln302_receive.spend(datum, redeemer, transaction.OutputReference { transaction_id: transaction.placeholder.id, output_index: 0 }, tx) == False
}

test uln302_verify_rejects_with_non_member_signer() {
  let local_eid = types.Eid(200)
  let receiver_b20 = bytearray.new(20)
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(1),
    src_eid: types.Eid(100),
    sender: types.Address32(bytearray.new(32)),
    dst_eid: local_eid,
    receiver_b20: types.Address20(receiver_b20),
  }
  let ph = codec.encode_header_v1(header)
  let hh = codec.header_hash_v1(ph)

  let guid = types.Guid(bytearray.from_hex("00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"))
  let msg = bytearray.from_utf8("hi")
  let plh = codec.payload_hash(guid, msg)

  let att: Data =
    builtin.constr_data(
      0,
      builtin.list_data([builtin.b_data(hh), builtin.b_data(plh), builtin.i_data(1)]),
    )

  let out_att = transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.zero,
    datum: transaction.Datum.InlineDatum(att),
    reference_script: None,
  }

  let pub_non_member = bytearray.from_hex("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
  let sig = bytearray.new(64)

  let out_sigs = mk_sigs_output(hh, plh, [sig], [pub_non_member])
  let out_ep = mk_endpoint_channel_inline(receiver_b20, 0, 1)

  let dvn_member = bytearray.from_hex("BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB")
  let dvn_in = mk_dvn_ref_input(1, 1, [dvn_member])
  let tx = transaction.Transaction { ..transaction.placeholder, reference_inputs: [dvn_in], outputs: [out_att, out_sigs, out_ep] }

  let datum = Some(uln302_receive.ReceiveDatum { local_eid: local_eid, dvn_vid: 1, required_quorum: 1, required_confirmations: 0 })
  let redeemer =
    uln302_receive.ReceiveRedeemer.Verify { packet_header: ph, payload_hash: plh, confirmations: 0 }

  expect uln302_receive.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: transaction.placeholder.id, output_index: 0 },
    tx
  ) == False
}

  expect uln302_receive.spend(datum, redeemer, transaction.OutputReference { transaction_id: transaction.placeholder.id, output_index: 0 }, tx) == False
}
test uln302_verify_accepts_with_real_ed25519_signature_quorum_1() {
  let local_eid = types.Eid(200)
  let receiver_b20 = bytearray.new(20)
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(1),
    src_eid: types.Eid(100),
    sender: types.Address32(bytearray.new(32)),
    dst_eid: local_eid,
    receiver_b20: types.Address20(receiver_b20),
  }
  let ph = codec.encode_header_v1(header)
  let hh = codec.header_hash_v1(ph)

  let guid = types.Guid(bytearray.from_hex("00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"))
  let msg = bytearray.from_utf8("hi")
  let plh = codec.payload_hash(guid, msg)

  let att: Data =
    builtin.constr_data(
      0,
      builtin.list_data([builtin.b_data(hh), builtin.b_data(plh), builtin.i_data(1)]),
    )
  let out_att = transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.zero,
    datum: transaction.Datum.InlineDatum(att),
    reference_script: None,
  }

  let pub = bytearray.from_hex("5172F998FC21A893DC69ADBDE3C8A80EAFCF8C40DB0C28845BC7D7C0739DBD7E")
  let sig = bytearray.from_hex("DD309BFBC91098A3F410BA69E3DBA06CE448A4AB9C8A8720697D117E1BBB81DA5F1A30AD1F9F0A84DD89E5B57504D5264468DF41E138242611BFDEC61CA7330A")

  let out_sigs = mk_sigs_output(hh, plh, [sig], [pub])
  let out_ep = mk_endpoint_channel_inline(receiver_b20, 0, 1)

  let dvn_in = mk_dvn_ref_input(1, 1, [pub])
  let tx = transaction.Transaction { ..transaction.placeholder, reference_inputs: [dvn_in], outputs: [out_att, out_sigs, out_ep] }

  let datum = Some(uln302_receive.ReceiveDatum { local_eid: local_eid, dvn_vid: 1, required_quorum: 1, required_confirmations: 0 })
  let redeemer = uln302_receive.ReceiveRedeemer.Verify { packet_header: ph, payload_hash: plh, confirmations: 0 }

  expect uln302_receive.spend(datum, redeemer, transaction.OutputReference { transaction_id: transaction.placeholder.id, output_index: 0 }, tx) == True
}
