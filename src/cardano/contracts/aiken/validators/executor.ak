use aiken/builtin

use layerzero/types

pub type ExecutorDatum {
  ExecutorDatum {
    local_eid: Types.Eid
  }
}

pub type NativeDropParam {
  NativeDropParam {
    receiver: Types.Address32,
    amount: Int,
  }
}

pub type LzReceiveParam {
  LzReceiveParam {
    origin: Types.Origin,
    receiver: Types.Address32,
    guid: Types.Guid,
    message: ByteArray,
    extra_data: ByteArray,
    gas: Int,
    value: Int,
  }
}

pub type ExecutorRedeemer {
  CommitAndExecute {
    receive_lib: ByteArray,
    lz_receive_param: LzReceiveParam,
    native_drops: List(NativeDropParam),
  }
}

pub fn validator(d: ExecutorDatum, r: ExecutorRedeemer, ctx: builtin.ScriptContext) -> Bool {
  builtin.trace("executor:commit_and_execute")
  case r {
    CommitAndExecute { .. } -> true
  }
}
