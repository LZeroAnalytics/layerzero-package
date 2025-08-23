use aiken/primitive/bytearray

use layerzero/types
use layerzero/codec
use layerzero/constants

test encode_header_v1_layout_simple() {
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(1),
    src_eid: types.Eid(100),
    sender: types.Address32(bytearray.new(32)), 
    dst_eid: types.Eid(200),
    receiver_b20: types.Address20(bytearray.new(20)),
  }

  let encoded = codec.encode_header_v1(header)

  let ver = codec.header_version(encoded)
  expect ver == bytearray.from_int_big_endian(constants.header_v1_version, 1)
  expect bytearray.length(encoded) == constants.header_v1_len

  let nonce_be = codec.header_nonce_be(encoded)
  expect nonce_be == bytearray.from_int_big_endian(1, 8)

  let src_eid_be = codec.header_src_eid_be(encoded)
  expect src_eid_be == bytearray.from_int_big_endian(100, 4)

  let dst_eid_be = codec.header_dst_eid_be(encoded)
  expect dst_eid_be == bytearray.from_int_big_endian(200, 4)

  let sender_b32 = codec.header_sender_b32(encoded)
  expect bytearray.length(sender_b32) == 32

  let recv_b20 = codec.header_receiver_b20(encoded)
  expect recv_b20 == types.Address20(bytearray.new(20))
}

test payload_hash_concatenation() {
  let gbytes = bytearray.from_hex("00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff")
  let guid = types.Guid(gbytes)
  let msg = bytearray.from_utf8("hello")

  let h = codec.payload_hash(guid, msg)

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

test parse_header_v1_round_trip() {
  let recv20 = bytearray.from_hex("0102030405060708090a0b0c0d0e0f1011121314")
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(42),
    src_eid: types.Eid(123),
    sender: types.Address32(bytearray.new(32)),
    dst_eid: types.Eid(456),
    receiver_b20: types.Address20(recv20),
  }
  let enc = codec.encode_header_v1(header)
  when codec.parse_header_v1(enc) is {
    Some(ph) -> {
      expect ph.nonce == types.Nonce(42)
      expect ph.src_eid == types.Eid(123)
      expect ph.dst_eid == types.Eid(456)
      expect ph.receiver_b20 == types.Address20(recv20)
    }
    None -> expect False == True
  }
}

test assert_header_v1_fails_wrong_length_and_version() {
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(9),
    src_eid: types.Eid(1),
    sender: types.Address32(bytearray.new(32)),
    dst_eid: types.Eid(2),
    receiver_b20: types.Address20(bytearray.new(20)),
  }
  let enc = codec.encode_header_v1(header)
  let shorter = bytearray.slice(enc, 0, 80)
  expect codec.assert_header_v1(shorter, types.Eid(2)) == False

  let wrong_ver = bytearray.concat(bytearray.from_int_big_endian(2, 1), bytearray.slice(enc, 1, bytearray.length(enc)))
  expect codec.assert_header_v1(wrong_ver, types.Eid(2)) == False
}

test header_src_and_sender_lengths() {
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(3),
    src_eid: types.Eid(55),
    sender: types.Address32(bytearray.new(32)),
    dst_eid: types.Eid(77),
    receiver_b20: types.Address20(bytearray.new(20)),
  }
  let enc = codec.encode_header_v1(header)
  let src_be = codec.header_src_eid_be(enc)
  let sender_b32 = codec.header_sender_b32(enc)
  expect bytearray.length(src_be) == 4
  expect bytearray.length(sender_b32) == 32
}

use aiken/primitive/bytearray

use layerzero/types
use layerzero/codec
use layerzero/constants

test encode_header_v1_layout_simple() {
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(1),
    src_eid: types.Eid(100),
    sender: types.Address32(bytearray.new(32)), 
    dst_eid: types.Eid(200),
    receiver_b20: types.Address20(bytearray.new(20)),
  }

  let encoded = codec.encode_header_v1(header)

  let ver = codec.header_version(encoded)
  expect ver == bytearray.from_int_big_endian(constants.header_v1_version, 1)
  expect bytearray.length(encoded) == constants.header_v1_len

  let nonce_be = codec.header_nonce_be(encoded)
  expect nonce_be == bytearray.from_int_big_endian(1, 8)

  let src_eid_be = codec.header_src_eid_be(encoded)
  expect src_eid_be == bytearray.from_int_big_endian(100, 4)

  let dst_eid_be = codec.header_dst_eid_be(encoded)
  expect dst_eid_be == bytearray.from_int_big_endian(200, 4)

  let sender_b32 = codec.header_sender_b32(encoded)
  expect bytearray.length(sender_b32) == 32

  let recv_b20 = codec.header_receiver_b20(encoded)
  expect recv_b20 == types.Address20(bytearray.new(20))
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
test parse_header_v1_round_trip() {
  let recv20 = bytearray.from_hex("0102030405060708090a0b0c0d0e0f1011121314")
  let header = types.PacketHeaderV1 {
    nonce: types.Nonce(42),
    src_eid: types.Eid(123),
    sender: types.Address32(bytearray.new(32)),
    dst_eid: types.Eid(456),
    receiver_b20: types.Address20(recv20),
  }
  let enc = codec.encode_header_v1(header)
  when codec.parse_header_v1(enc) is {
    Some(ph) -> {
      expect ph.nonce == types.Nonce(42)
      expect ph.src_eid == types.Eid(123)
      expect ph.dst_eid == types.Eid(456)
      expect ph.receiver_b20 == types.Address20(recv20)
    }
    None -> expect False == True
  }
}
