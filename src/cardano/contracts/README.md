# Cardano LayerZero (Aiken)

This folder contains the Aiken-based Cardano implementation of LayerZero V2 core on-chain components.

Contents
- aiken/
  - validators/
    - endpoint.ak
    - uln302_send.ak
    - uln302_receive.ak
    - executor.ak
    - dvn.ak
  - lib/
    - layerzero/
      - types.ak
      - codec.ak
      - constants.ak
      - dvn_helpers.ak
      - endpoint_helpers.ak
  - tests/
    - codec.tests.ak
    - endpoint.tests.ak
    - endpoint_validator.tests.ak
    - uln302_send.tests.ak
    - uln302_receive.tests.ak
    - executor_commit.tests.ak
    - dvn.tests.ak
    - dvn_execute.tests.ak
  - aiken.toml

What’s implemented
- Endpoint: per-(origin, receiver) channel UTXOs for inbound nonce and executable-state tracking.
- ULN302 Send/Receive: config handling, header assertions, atomic Endpoint.Verify requirement, fee routing checks.
- Executor: Commit-and-Execute with Endpoint IO atomicity and fee-output enforcement.
- DVN: Ed25519 multisig with configurable signer set and quorum; admin flows for signer/quorum updates.
- Codecs: Packet V1 header encoder/decoder and hashing aligned to EVM fixed-width layout.

How to run
- Install Aiken: https://aiken-lang.org/
- From this directory:
  - cd src/cardano/contracts/aiken
  - aiken check

This compiles and collects the test suite, which includes:
- DVN multisig verification (positive with real Ed25519 signature) and negative cases (insufficient quorum, non-member, duplicates).
- Endpoint nonce monotonicity and executable gating.
- ULN302 Send outbound datum and fee routing checks.
- Executor commit-and-execute atomicity.

Notes
- No secrets are embedded; tests use deterministic vectors.
- Behavior mirrors LayerZero V2 EVM/altVM where applicable, adapted to Cardano’s eUTXO model.
