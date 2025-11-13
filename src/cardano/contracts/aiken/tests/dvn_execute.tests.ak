use aiken/builtin
use cardano/transaction
use cardano/address
use cardano/assets

use layerzero/types
use layerzero/validators/dvn

fn mk_attestation(hh: ByteArray, ph: ByteArray, sc: Int) -> Data {
  builtin.constr_data(0, builtin.list_data([builtin.b_data(hh), builtin.b_data(ph), builtin.i_data(sc)]))
}

fn mk_sigs(hh: ByteArray, ph: ByteArray, pubs: List<types.Address32>, sigs: List<ByteArray>) -> Data {
  let pubs_d = list.map(pubs, fn(p) { let types.Address32(b) = p; builtin.constr_data(0, builtin.list_data([builtin.b_data(b)])) })
  let sigs_d = list.map(sigs, fn(s) { builtin.b_data(s) })
  builtin.constr_data(
    1,
    builtin.list_data([builtin.b_data(hh), builtin.b_data(ph), builtin.list_data(sigs_d), builtin.list_data(pubs_d)]),
  )
}

test dvn_execute_rejects_when_multisig_not_satisfied() {
  let hh = #"11"
  let ph = #"22"
  let pk1 = types.Address32(#"01")
  let att = mk_attestation(hh, ph, 1)
  let sigsd = mk_sigs(hh, ph, [pk1], [])
  let out1 = transaction.Output { address: address.from_verification_key(#"aa"), value: assets.zero, datum: transaction.Datum.InlineDatum(att), reference_script: None }
  let out2 = transaction.Output { address: address.from_verification_key(#"bb"), value: assets.zero, datum: transaction.Datum.InlineDatum(sigsd), reference_script: None }
  let tx = transaction.Transaction { ..transaction.placeholder, outputs: [out1, out2] }
  let datum = Some(dvn.DvnDatum { vid: 1, quorum: 1, signers: [pk1] })
  let redeemer = dvn.DvnRedeemer.Execute { params: [dvn.ExecuteParam { vid: 1, header_hash: hh, payload_hash: ph, signer_count: 1 }] }
  expect dvn.spend(datum, redeemer, transaction.OutputReference { transaction_id: tx.id, output_index: 0 }, tx) == False
}
use aiken/builtin
use cardano/address
use cardano/assets
use cardano/transaction

use layerzero/validators/dvn

test dvn_execute_accepts_when_attestation_meets_quorum() {
  let hh = #"0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20"
  let ph = #"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"

  let att: Data =
    builtin.constr_data(
      0,
      builtin.list_data([builtin.b_data(hh), builtin.b_data(ph), builtin.i_data(2)]),
    )

  let out = transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.zero,
    datum: transaction.Datum.InlineDatum(att),
    reference_script: None,
  }

  let tx = transaction.Transaction { ..transaction.placeholder, outputs: [out] }

  let datum = Some(dvn.DvnDatum { vid: 1, quorum: 2 })

  let params: List<dvn.ExecuteParam> =
    [
      dvn.ExecuteParam {
        vid: 1,
        header_hash: hh,
        payload_hash: ph,
        signer_count: 2,
      },
    ]

  let redeemer = dvn.DvnRedeemer.Execute { params: params }

  expect dvn.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: transaction.placeholder.id, output_index: 0 },
    tx
  ) == True
}

test dvn_execute_rejects_when_attestation_below_quorum() {
  let hh = #"0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20"
  let ph = #"abababababababababababababababababababababababababababababababab"

  let att: Data =
    builtin.constr_data(
      0,
      builtin.list_data([builtin.b_data(hh), builtin.b_data(ph), builtin.i_data(1)]),
    )

  let out = transaction.Output {
    address: address.from_verification_key(#"00"),
    value: assets.zero,
    datum: transaction.Datum.InlineDatum(att),
    reference_script: None,
  }

  let tx = transaction.Transaction { ..transaction.placeholder, outputs: [out] }

  let datum = Some(dvn.DvnDatum { vid: 1, quorum: 2 })

  let params: List<dvn.ExecuteParam> =
    [
      dvn.ExecuteParam {
        vid: 1,
        header_hash: hh,
        payload_hash: ph,
        signer_count: 1,
      },
    ]

  let redeemer = dvn.DvnRedeemer.Execute { params: params }

  expect dvn.spend(
    datum,
    redeemer,
    transaction.OutputReference { transaction_id: transaction.placeholder.id, output_index: 0 },
    tx
  ) == False
}
