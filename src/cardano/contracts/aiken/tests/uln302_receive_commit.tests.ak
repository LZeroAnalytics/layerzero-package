use cardano/transaction

use layerzero/types
use layerzero/codec
use layerzero/validators/uln302_receive

test uln302_commitverification_accepts_when_header_dst_matches_local_eid() {
  let local = types.Eid(200)
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(10),
    src_eid: types.Eid(100),
    sender: types.Address32(bytearray.new(32)),
    dst_eid: local,
    receiver_b20: types.Address20(bytearray.new(20)),
  }
  let ph = codec.encode_header_v1(header)

  let datum = Some(uln302_receive.ReceiveDatum { local_eid: local, dvn_vid: 1, required_quorum: 1, required_confirmations: 0 })
  let redeemer = uln302_receive.ReceiveRedeemer.CommitVerification {
    packet_header: ph,
    payload_hash: bytearray.new(32),
  }
  let tx = transaction.placeholder

  expect uln302_receive.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: tx.id, output_index: 0 },
    tx
  ) == True
}

test uln302_commitverification_rejects_when_header_dst_mismatch() {
  let local = types.Eid(201)
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(11),
    src_eid: types.Eid(100),
    sender: types.Address32(bytearray.new(32)),
    dst_eid: types.Eid(200),
    receiver_b20: types.Address20(bytearray.new(20)),
  }
  let ph = codec.encode_header_v1(header)

  let datum = Some(uln302_receive.ReceiveDatum { local_eid: local, dvn_vid: 1, required_quorum: 1, required_confirmations: 0 })
  let redeemer = uln302_receive.ReceiveRedeemer.CommitVerification {
    packet_header: ph,
    payload_hash: bytearray.new(32),
  }
  let tx = transaction.placeholder

  expect uln302_receive.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: tx.id, output_index: 0 },
    tx
  ) == False
}
