use aiken/builtin
use aiken/primitive/bytearray

use layerzero/types

pub fn encode_address32(types.Address32(bytes)) -> ByteArray {
  bytes
}

pub fn encode_address20(types.Address20(bytes)) -> ByteArray {
  bytes
}

pub fn encode_eid(types.Eid(e)) -> ByteArray {
  builtin.serialize_data(e)
}

pub fn encode_nonce(types.Nonce(n)) -> ByteArray {
  builtin.serialize_data(n)
}

pub fn encode_header_v1(h: types.PacketHeaderV1) -> ByteArray {
  let b0 = bytearray.from_int_big_endian(1, 1)
  let b1 = encode_nonce(h.nonce)
  let b2 = encode_eid(h.src_eid)
  let b3 = encode_address32(h.sender)
  let b4 = encode_eid(h.dst_eid)
  let b5 = encode_address20(h.receiver_b20)
  bytearray.concat([b0, b1, b2, b3, b4, b5])
}

pub fn payload_hash(guid: types.Guid, message: ByteArray) -> ByteArray {
  builtin.blake2b_256(bytearray.concat(unwrap_guid(guid), message))
}

fn unwrap_guid(types.Guid(b)) -> ByteArray {
  b
}
