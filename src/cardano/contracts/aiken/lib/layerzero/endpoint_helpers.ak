use layerzero/types

pub fn nonce_next_ok(current: types.Nonce, incoming: types.Nonce) -> Bool {
  let types.Nonce(c) = current
  let types.Nonce(n) = incoming
  n == c + 1
}

pub type ChannelState {
  ChannelState {
    lazy_inbound_nonce: types.Nonce,
    executable: Bool,
  }
}

pub fn mark_verifiable(s: ChannelState, incoming: types.Nonce) -> ChannelState {
  if nonce_next_ok(s.lazy_inbound_nonce, incoming) {
    ChannelState {
      lazy_inbound_nonce: s.lazy_inbound_nonce,
      executable: True,
    }
  } else {
    s
  }
}

pub fn consume_executable_and_advance(s: ChannelState, incoming: types.Nonce) -> ChannelState {
  let types.Nonce(c) = s.lazy_inbound_nonce
  let types.Nonce(n) = incoming
  if s.executable == True && n == c + 1 {
    ChannelState {
      lazy_inbound_nonce: types.Nonce(n),
      executable: False,
    }
  } else {
    s
  }
}
