use aiken/builtin
use aiken/collection/list
use aiken/primitive/bytearray
use cardano/address
use cardano/assets
use cardano/transaction

use layerzero/types
use layerzero/validators/dvn
use layerzero/dvn_helpers

fn mk_dvn_output(vid: Int, quorum: Int, signers: List<ByteArray>, admin_vkh: ByteArray) -> transaction.Output {
  let signers_list = list.map(signers, fn(p) { builtin.constr_data(0, builtin.list_data([ builtin.b_data(p) ])) })
  let dvn_datum =
    builtin.constr_data(
      0,
      builtin.list_data([
        builtin.i_data(vid),
        builtin.i_data(quorum),
        builtin.list_data(signers_list),
        builtin.b_data(admin_vkh),
      ]),
    )
  transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.zero,
    datum: transaction.Datum.InlineDatum(dvn_datum),
    reference_script: None,
  }
}

fn mk_dvn_input(vid: Int, quorum: Int, signers: List<ByteArray>, admin_vkh: ByteArray) -> transaction.Input {
  let out = mk_dvn_output(vid, quorum, signers, admin_vkh)
  transaction.Input {
    output_reference: transaction.OutputReference { transaction_id: transaction.placeholder.id, output_index: 0 },
    output: out,
  }
}

test quorum_satisfied_exact() {
  expect dvn_helpers.quorum_satisfied(3, 3) == True
}

test quorum_satisfied_over() {
  expect dvn_helpers.quorum_satisfied(5, 3) == True
}

test quorum_not_satisfied_under() {
  expect dvn_helpers.quorum_satisfied(2, 3) == False
}

test dvn_admin_can_update_signers() {
  let admin = #"AB"
  let in_signers: List<ByteArray> = [#"11"]
  let out_signers: List<ByteArray> = [#"11", #"22"]

  let dvn_in = mk_dvn_input(1, 1, in_signers, admin)
  let dvn_out = mk_dvn_output(1, 1, out_signers, admin)

  let tx =
    transaction.Transaction {
      ..transaction.placeholder,
      inputs: [dvn_in],
      outputs: [dvn_out],
      extra_signatories: [admin],
    }

  let datum = Some(dvn.DvnDatum { vid: 1, quorum: 1, signers: in_signers |> list.map(fn(p) { types.Address32(p) }), admin: admin })
  let redeemer = dvn.DvnRedeemer.SetSignerSet { signers: out_signers |> list.map(fn(p) { types.Address32(p) }) }

  expect dvn.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: transaction.placeholder.id, output_index: 0 },
    tx
  ) == True
}

test dvn_non_admin_cannot_update_quorum() {
  let admin = #"CD"
  let dvn_in = mk_dvn_input(2, 1, [], admin)
  let dvn_out = mk_dvn_output(2, 2, [], admin)

  let tx =
    transaction.Transaction {
      ..transaction.placeholder,
      inputs: [dvn_in],
      outputs: [dvn_out],
      extra_signatories: [#"EE"],
    }

  let datum = Some(dvn.DvnDatum { vid: 2, quorum: 1, signers: [], admin: admin })
  let redeemer = dvn.DvnRedeemer.SetQuorum { quorum: 2 }

  expect dvn.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: transaction.placeholder.id, output_index: 0 },
    tx
  ) == False
}
