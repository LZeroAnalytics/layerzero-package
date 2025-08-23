use aiken/builtin
use aiken/collection/list
use aiken/primitive/bytearray
use cardano/address
use cardano/assets
use cardano/transaction

use layerzero/types
use layerzero/validators/uln302_send

fn mk_outbound_inline(header: ByteArray, payload: ByteArray, options_len: Int) -> transaction.Output {
  let datum: Data =
    builtin.constr_data(
      0,
      builtin.list_data([builtin.b_data(header), builtin.b_data(payload), builtin.i_data(options_len)]),
    )
  transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.zero,
    datum: transaction.Datum.InlineDatum(datum),
    reference_script: None,
  }
}

test uln302_send_accepts_when_outbound_present_and_options_len_matches() {
  let header = bytearray.from_int_big_endian(1, 1)
    |> bytearray.concat(bytearray.from_int_big_endian(0, 80))
  let payload = bytearray.from_utf8("msg")
  let out = mk_outbound_inline(header, payload, 2)

  let tx = transaction.Transaction { ..transaction.placeholder, outputs: [out] }

  let datum = Some(uln302_send.SendDatum {
    oapp: types.Address32(bytearray.new(32)),
    dst_eid: types.Eid(200),
    executor_cfg: types.ExecutorConfig { placeholder: 0 },
    uln_cfg: types.UlnConfig { confirmations: 0, quorum: 0 },
  })

  let opts: List<types.WorkerOption> = [
    types.WorkerOption { key: #"01", value: #"aa" },
    types.WorkerOption { key: #"02", value: #"bb" },
  ]

  let redeemer = uln302_send.SendRedeemer.Send { options: opts }

  expect uln302_send.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: transaction.placeholder.id, output_index: 0 },
    tx
  ) == True
}

test uln302_send_rejects_when_header_wrong_length_or_options_mismatch() {
  let bad_header = bytearray.from_int_big_endian(1, 1)
    |> bytearray.concat(bytearray.from_int_big_endian(0, 79))
  let payload = bytearray.from_utf8("msg")
  let out = mk_outbound_inline(bad_header, payload, 1)

  let tx = transaction.Transaction { ..transaction.placeholder, outputs: [out] }

  let datum = Some(uln302_send.SendDatum {
    oapp: types.Address32(bytearray.new(32)),
    dst_eid: types.Eid(200),
    executor_cfg: types.ExecutorConfig { placeholder: 0 },
    uln_cfg: types.UlnConfig { confirmations: 0, quorum: 0 },
  })

  let opts: List<types.WorkerOption> = [
    types.WorkerOption { key: #"01", value: #"aa" },
    types.WorkerOption { key: #"02", value: #"bb" },
  ]

  let redeemer = uln302_send.SendRedeemer.Send { options: opts }

  expect uln302_send.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: transaction.placeholder.id, output_index: 0 },
    tx
  ) == False
}
