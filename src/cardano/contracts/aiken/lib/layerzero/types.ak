
pub type Eid {
  Eid(Int)
}

pub type Nonce {
  Nonce(Int)
}

pub type Address32 {
  Address32(ByteArray)
}

pub type Address20 {
  Address20(ByteArray)
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

pub type PacketHeaderV1 {
  PacketHeaderV1 {
    nonce: Nonce,
    src_eid: Eid,
    sender: Address32,
    dst_eid: Eid,
    receiver_b20: Address20,
  }
}

pub type ExecutorConfig {
  ExecutorConfig {
    placeholder: Int
  }
}

pub type UlnConfig {
  UlnConfig {
    confirmations: Int,
    quorum: Int
  }
}

pub type WorkerOption {
  WorkerOption {
    key: ByteArray,
    value: ByteArray
  }
}

pub type GuidAndMessage {
  GuidAndMessage {
    guid: Guid,
    message: ByteArray
  }
}

pub type AttestationDatum {
  AttestationDatum {
    header_hash: ByteArray,
    payload_hash: ByteArray,
    signer_count: Int
  }
}
