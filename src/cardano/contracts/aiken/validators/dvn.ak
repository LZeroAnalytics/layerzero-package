use aiken/builtin

use LayerZero/Types

pub type DvnDatum {
  DvnDatum {
    vid: Int,
    quorum: Int,
  }
}

pub type ExecuteParam {
  ExecuteParam {
    vid: Int,
    target: ByteArray,
    call_data: ByteArray,
    expiration: Int,
    signatures: ByteArray,
  }
}

pub type AssignJobParam {
  AssignJobParam {
    dst_eid: Types.Eid,
    confirmations: Int,
    sender: Types.Address32,
  }
}

pub type DvnRedeemer {
  SetSigner {
    signer: Types.Address32,
    active: Bool,
  }
  SetQuorum {
    quorum: Int,
  }
  AssignJob {
    param: AssignJobParam,
    options: ByteArray,
  }
  Execute {
    params: List(ExecuteParam),
  }
}

pub fn validator(d: DvnDatum, r: DvnRedeemer, ctx: builtin.ScriptContext) -> Bool {
  builtin.trace("dvn:dispatch")
  case r {
    SetSigner { .. } -> true
    SetQuorum { .. } -> true
    AssignJob { .. } -> true
    Execute { .. } -> true
  }
}
