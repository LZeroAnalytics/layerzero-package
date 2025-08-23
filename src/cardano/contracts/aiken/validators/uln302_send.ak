use aiken/builtin

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
  fn spend(d: SendDatum, r: SendRedeemer, ctx: builtin.ScriptContext) -> Bool {
    builtin.trace("uln302_send:dispatch")
    case r {
      SetConfigExec { .. } -> true
      SetConfigUln { .. } -> true
      Send { .. } -> true
    }
  }
}
