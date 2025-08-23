use cardano/transaction.{OutputReference, Transaction}

use layerzero/types

pub type SendDatum {
  SendDatum {
    oapp: types.Address32,
    dst_eid: types.Eid,
    executor_cfg: types.ExecutorConfig,
    uln_cfg: types.UlnConfig,
  }
}

pub type SendRedeemer {
  SetConfigExec {
    oapp: types.Address32,
    dst_eid: types.Eid,
    cfg: types.ExecutorConfig,
  }
  SetConfigUln {
    oapp: types.Address32,
    dst_eid: types.Eid,
    cfg: types.UlnConfig,
  }
  Send {
    options: List<types.WorkerOption>,
  }
}

validator uln302_send {
  spend(
    _datum: Option<SendDatum>,
    redeemer: SendRedeemer,
    _0: OutputReference,
    _1: Transaction,
  ) {
    when redeemer is {
      SetConfigExec { oapp: _, dst_eid: _, cfg: _ } -> True
      SetConfigUln { oapp: _, dst_eid: _, cfg: _ } -> True
      Send { options: _ } -> True
    }
  }

  else(_) {
    fail
  }
}
