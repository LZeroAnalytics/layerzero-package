use aiken/builtin
use aiken/builtin
use aiken/primitive/bytearray

use layerzero/types
use layerzero/types.{Address32, Address20, Eid, Nonce, Guid, PacketHeaderV1}

pub fn header_hash_v1(header: ByteArray) -> ByteArray {
  builtin.blake2b_256(header)
}

pub fn encode_address32(a) -> ByteArray {
  let Address32(bytes) = a
  bytes
}

pub fn encode_address20_to_bytes32(a) -> ByteArray {
  let Address20(b20) = a
  let pad = bytearray.from_int_big_endian(0, 12)
  bytearray.concat(pad, b20)
}

pub fn encode_eid(a) -> ByteArray {
  let Eid(e) = a
  bytearray.from_int_big_endian(e, 4)
}

pub fn encode_nonce(a) -> ByteArray {
  let Nonce(n) = a
  bytearray.from_int_big_endian(n, 8)
}

pub fn encode_header_v1(h: types.PacketHeaderV1) -> ByteArray {
  let b0 = bytearray.from_int_big_endian(1, 1)
  let b1 = encode_nonce(h.nonce)
  let b2 = encode_eid(h.src_eid)
  let b3 = encode_address32(h.sender)
  let b4 = encode_eid(h.dst_eid)
  let b5 = encode_address20_to_bytes32(h.receiver_b20)
  let b01 = bytearray.concat(b0, b1)
  let b23 = bytearray.concat(b2, b3)
  let b45 = bytearray.concat(b4, b5)
  bytearray.concat(bytearray.concat(b01, b23), b45)
}

pub fn payload_hash(guid: types.Guid, message: ByteArray) -> ByteArray {
  builtin.blake2b_256(bytearray.concat(unwrap_guid(guid), message))
}

pub fn header_version(header: ByteArray) -> ByteArray {
  bytearray.slice(header, 0, 1)
}

pub fn header_nonce_be(header: ByteArray) -> ByteArray {
  bytearray.slice(header, 1, 9)
}

pub fn header_src_eid_be(header: ByteArray) -> ByteArray {
  bytearray.slice(header, 9, 13)
}

pub fn header_sender_b32(header: ByteArray) -> ByteArray {
  bytearray.slice(header, 13, 45)
}

pub fn header_dst_eid_be(header: ByteArray) -> ByteArray {
  bytearray.slice(header, 45, 49)
}

pub fn hash_header(header: ByteArray) -> ByteArray {
  builtin.blake2b_256(header)
}

pub fn header_dst_eid(header: ByteArray) -> types.Eid {
  let be = header_dst_eid_be(header)
  types.Eid(bytearray.to_int_big_endian(be))
}

pub fn header_nonce(header: ByteArray) -> types.Nonce {
  let be = header_nonce_be(header)
  types.Nonce(bytearray.to_int_big_endian(be))
}

pub fn parse_header_v1(header: ByteArray) -> Option<types.PacketHeaderV1> {
  if bytearray.length(header) != 81 {
    None
  } else {
    let ver = header_version(header)
    if ver == bytearray.from_int_big_endian(1, 1) {
      let nonce = header_nonce(header)
      let src_eid = types.Eid(bytearray.to_int_big_endian(header_src_eid_be(header)))
      let sender_b32 = header_sender_b32(header)
      let dst_eid = header_dst_eid(header)
      let recv20 = header_receiver_b20(header)
      Some(types.PacketHeaderV1 {
        nonce: nonce,
        src_eid: src_eid,
        sender: types.Address32(sender_b32),
        dst_eid: dst_eid,
        receiver_b20: recv20,
      })
    } else {
      None
    }
  }
}



fn unwrap_guid(g) -> ByteArray {
  let Guid(b) = g
  b
}
pub fn assert_header_v1(header: ByteArray, local_eid: types.Eid) -> Bool {
  // length must be 81 bytes as per EVM PacketV1 header
  if bytearray.length(header) != 81 {
    False
  } else {
    let version = bytearray.slice(header, 0, 1)
    let expected_version = bytearray.from_int_big_endian(1, 1)
    let dst_eid_be = bytearray.slice(header, 45, 49)
    let types.Eid(eid_int) = local_eid
    let expected_dst_eid = bytearray.from_int_big_endian(eid_int, 4)
    version == expected_version && dst_eid_be == expected_dst_eid
  }
}

pub fn header_receiver_b20(header: ByteArray) -> types.Address20 {
  // receiver is bytes32 at offset 49..81; take last 20 bytes
  let receiver_b32 = bytearray.slice(header, 49, 81)
  let b20 = bytearray.slice(receiver_b32, 12, 32)
  types.Address20(b20)
}
