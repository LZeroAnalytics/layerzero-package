use aiken/builtin

use layerzero/types

pub type ExecutorDatum {
  ExecutorDatum {
    local_eid: types.Eid
  }
}

pub type NativeDropParam {
  NativeDropParam {
    receiver: types.Address32,
    amount: Int,
  }
}

pub type LzReceiveParam {
  LzReceiveParam {
    origin: types.Origin,
    receiver: types.Address32,
    guid: types.Guid,
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
    native_drops: List<NativeDropParam>,
  }
}

validator executor {
  fn spend(d: ExecutorDatum, r: ExecutorRedeemer, ctx: builtin.ScriptContext) -> Bool {
    builtin.trace("executor:commit_and_execute")
    case r {
      CommitAndExecute { .. } -> true
    }
  }
}
