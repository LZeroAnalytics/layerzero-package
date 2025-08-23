use aiken/builtin

use layerzero/types

pub type SendDatum {
  SendDatum {
    oapp: Types.Address32,
    dst_eid: Types.Eid,
    executor_cfg: Types.ExecutorConfig,
    uln_cfg: Types.UlnConfig,
  }
}

pub type SendRedeemer {
  SetConfigExec {
    oapp: Types.Address32,
    dst_eid: Types.Eid,
    cfg: Types.ExecutorConfig,
  }
  SetConfigUln {
    oapp: Types.Address32,
    dst_eid: Types.Eid,
    cfg: Types.UlnConfig,
  }
  Send {
    options: List(Types.WorkerOption),
  }
}

pub fn validator(d: SendDatum, r: SendRedeemer, ctx: builtin.ScriptContext) -> Bool {
  builtin.trace("uln302_send:dispatch")
  case r {
    SetConfigExec { .. } -> true
    SetConfigUln { .. } -> true
    Send { .. } -> true
  }
}
