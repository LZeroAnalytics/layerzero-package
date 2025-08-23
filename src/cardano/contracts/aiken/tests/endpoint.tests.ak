use layerzero/types
use layerzero/endpoint_helpers

test nonce_next_ok_true() {
  let cur = types.Nonce(5)
  let next = types.Nonce(6)
  expect endpoint_helpers.nonce_next_ok(cur, next) == True
}

test nonce_next_ok_false_same() {
  let cur = types.Nonce(5)
  let next = types.Nonce(5)
  expect endpoint_helpers.nonce_next_ok(cur, next) == False
}

test mark_verifiable_sets_flag_only_when_monotonic() {
  let s = endpoint_helpers.ChannelState {
    lazy_inbound_nonce: types.Nonce(10),
    executable: False,
  }
  let s2 = endpoint_helpers.mark_verifiable(s, types.Nonce(11))
  expect s2.executable == True
  let s3 = endpoint_helpers.mark_verifiable(s, types.Nonce(12))
  expect s3.executable == False
}

test consume_executable_and_advance_happy_path() {
  let s0 = endpoint_helpers.ChannelState {
    lazy_inbound_nonce: types.Nonce(10),
    executable: True,
  }
  let s1 = endpoint_helpers.consume_executable_and_advance(s0, types.Nonce(11))
  expect s1.executable == False
  expect s1.lazy_inbound_nonce == types.Nonce(11)
}

test consume_executable_blocks_if_not_executable() {
  let s0 = endpoint_helpers.ChannelState {
    lazy_inbound_nonce: types.Nonce(10),
    executable: False,
  }
  let s1 = endpoint_helpers.consume_executable_and_advance(s0, types.Nonce(11))
  expect s1 == s0
}
