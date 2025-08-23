use cardano/transaction.{OutputReference, Transaction}

use layerzero/types

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
    dst_eid: types.Eid,
    confirmations: Int,
    sender: types.Address32,
  }
}

pub type DvnRedeemer {
  SetSigner {
    signer: types.Address32,
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
    params: List<ExecuteParam>,
  }
}

validator dvn {
  spend(
    _datum: Option<DvnDatum>,
    redeemer: DvnRedeemer,
    _0: OutputReference,
    _1: Transaction,
  ) {
    when redeemer is {
      SetSigner { signer: _, active: _ } -> True
      SetQuorum { quorum: _ } -> True
      AssignJob { param: _, options: _ } -> True
      Execute { params: _ } -> True
    }
  }

  else(_) {
    fail
  }
}
