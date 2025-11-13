use aiken/collection/list
use aiken/primitive/bytearray
use aiken/builtin

use layerzero/types

pub fn quorum_satisfied(sc: Int, q: Int) -> Bool {
  sc >= q && q > 0
}

pub fn attestation_message(hh: ByteArray, ph: ByteArray) -> ByteArray {
  bytearray.concat(hh, ph)
}

pub fn unique_signers(pubs: List<types.Address32>) -> Bool {
  let seen =
    list.foldr(
      pubs,
      [],
      fn(p, acc) {
        let types.Address32(b) = p
        if list.any(acc, fn(x) { x == b }) {
          acc
        } else {
          [b, ..acc]
        }
      },
    )
  list.length(seen) == list.length(pubs)
}

pub fn signers_within_set(pubs: List<types.Address32>, set: List<types.Address32>) -> Bool {
  pubs
    |> list.all(fn(p) {
      let types.Address32(b) = p
      list.any(set, fn(s) {
        let types.Address32(sb) = s
        sb == b
      })
    })
}

pub fn verify_multisig(
  message: ByteArray,
  pubs: List<types.Address32>,
  sigs: List<ByteArray>,
  quorum: Int,
) -> Bool {
  let pairs = list.zip(pubs, sigs)
  let valid = list.foldr(
    pairs,
    0,
    fn(pair, acc) {
      let p = pair.1st
      let s = pair.2nd
      let types.Address32(pk) = p
      let ok = builtin.verify_ed25519_signature(pk, message, s)
      acc + if ok { 1 } else { 0 }
    },
  )
  valid >= quorum && quorum > 0
}
