use aiken/builtin
use aiken/primitive/bytearray

use layerzero/types
use layerzero/types.{Address32, Address20, Eid, Nonce, Guid, PacketHeaderV1}

pub fn encode_address32(a) -> ByteArray {
  when a is {
    Address32(bytes) -> bytes
  }
}

pub fn encode_address20(a) -> ByteArray {
  when a is {
    Address20(bytes) -> bytes
  }
}

pub fn encode_eid(a) -> ByteArray {
  when a is {
    Eid(e) -> builtin.serialise_data(e)
  }
}

pub fn encode_nonce(a) -> ByteArray {
  when a is {
    Nonce(n) -> builtin.serialise_data(n)
  }
}

pub fn encode_header_v1(h: types.PacketHeaderV1) -> ByteArray {
  let b0 = bytearray.from_int_big_endian(1, 1)
  let b1 = encode_nonce(h.nonce)
  let b2 = encode_eid(h.src_eid)
  let b3 = encode_address32(h.sender)
  let b4 = encode_eid(h.dst_eid)
  let b5 = encode_address20(h.receiver_b20)
  let b01 = bytearray.concat(b0, b1)
  let b23 = bytearray.concat(b2, b3)
  let b45 = bytearray.concat(b4, b5)
  bytearray.concat(bytearray.concat(b01, b23), b45)
}

pub fn payload_hash(guid: types.Guid, message: ByteArray) -> ByteArray {
  builtin.blake2b_256(bytearray.concat(unwrap_guid(guid), message))
}

fn unwrap_guid(g) -> ByteArray {
  when g is {
    Guid(b) -> b
  }
}
