use aiken/collection/list
use cardano/transaction.{OutputReference, Transaction}
use cardano/assets

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

fn sum_native_drops(ds: List<NativeDropParam>) -> Int {
  list.foldr(ds, 0, fn(d, acc) { d.amount + acc })
}

fn total_outputs_lovelace(tx: Transaction) -> Int {
  list.foldr(
    tx.outputs,
    0,
    fn(o, acc) { assets.lovelace_of(o.value) + acc },
  )
}

validator executor {
  spend(
    _datum: Option<ExecutorDatum>,
    redeemer: ExecutorRedeemer,
    _0: OutputReference,
    tx: Transaction,
  ) {
    let CommitAndExecute { receive_lib: _, lz_receive_param: _, native_drops: drops } = redeemer
    let need = sum_native_drops(drops)
    let have = total_outputs_lovelace(tx)
    have >= need && need >= 0
  }

  else(_) {
    fail
  }
}
