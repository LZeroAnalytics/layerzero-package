pub type Eid {
  Eid(Int)
}

pub type Address20 {
  Address20(ByteArray)
}

pub type Address32 {
  Address32(ByteArray)
}

pub type Nonce {
  Nonce(Int)
}

pub type Guid {
  Guid(ByteArray)
}

pub type Origin {
  Origin {
    src_eid: Eid,
    sender: Address32,
    nonce: Nonce,
  }
}

pub type WorkerOption {
  WorkerOption(ByteArray)
}

pub type VerificationState {
  Verifiable
  Verifying
  NotVerifiable
}

pub type ExecutorConfig {
  ExecutorConfig {
    gas_limit: Int,
    gas_for_fee_cap: Int,
  }
}

pub type UlnConfig {
  UlnConfig {
    quorum: Int,
    confirmations: Int,
  }
}

pub type PacketHeaderV1 {
  PacketHeaderV1 {
    nonce: Nonce,
    src_eid: Eid,
    sender: Address32,
    dst_eid: Eid,
    receiver_b20: Address20,
  }
}
