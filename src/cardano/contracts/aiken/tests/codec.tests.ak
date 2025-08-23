use aiken/primitive/bytearray

use layerzero/types
use layerzero/codec

test encode_header_v1_layout_simple() {
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(1),
    src_eid: types.Eid(100),
    sender: types.Address32(bytearray.new(32)), 
    dst_eid: types.Eid(200),
    receiver_b20: types.Address20(bytearray.new(20)),
  }

  let encoded = codec.encode_header_v1(header)

  // version byte + encoded fields; we assert prefix is version 1 and total length is 81 bytes
  let ver = bytearray.slice(encoded, 0, 1)
  expect ver == bytearray.from_int_big_endian(1, 1)
  expect bytearray.length(encoded) == 81
  // quick spot-check offsets: nonce is 8 bytes after version, srcEid next 4 bytes
  let nonce_be = bytearray.slice(encoded, 1, 9)
  expect nonce_be == bytearray.from_int_big_endian(1, 8)
  let src_eid_be = bytearray.slice(encoded, 9, 13)
  expect src_eid_be == bytearray.from_int_big_endian(100, 4)
}

test payload_hash_concatenation() {
  let gbytes = bytearray.from_hex("00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff")
  let guid = types.Guid(gbytes)
  let msg = bytearray.from_utf8("hello")

  let h = codec.payload_hash(guid, msg)

  // sanity checks: length 32 and deterministic for same inputs
  expect bytearray.length(h) == 32
  let h2 = codec.payload_hash(guid, msg)
  expect h == h2
}
  
test assert_header_v1_checks() {
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(1),
    src_eid: types.Eid(100),
    sender: types.Address32(bytearray.new(32)),
    dst_eid: types.Eid(200),
    receiver_b20: types.Address20(bytearray.new(20)),
  }
  let encoded = codec.encode_header_v1(header)
  expect codec.assert_header_v1(encoded, types.Eid(200)) == True
  expect codec.assert_header_v1(encoded, types.Eid(201)) == False
}
  
test header_receiver_b20_extracts_correct_address() {
  let recv20 = bytearray.from_hex("aabbccddeeff00112233445566778899aabbccdd")
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(7),
    src_eid: types.Eid(1234),
    sender: types.Address32(bytearray.new(32)),
    dst_eid: types.Eid(9999),
    receiver_b20: types.Address20(recv20),
  }
  let encoded = codec.encode_header_v1(header)
  let extracted = codec.header_receiver_b20(encoded)
  expect extracted == types.Address20(recv20)
}
