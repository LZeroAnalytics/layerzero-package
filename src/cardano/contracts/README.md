# Cardano LayerZero Contracts (Aiken)

This directory contains the Cardano eUTXO adaptations of LayerZero V2 core contracts implemented in Aiken.

Structure:
- aiken/                  Aiken project root
  - aiken.toml            Project config
  - validators/           On-chain validators (scripts)
  - lib/                  Shared libraries (types, codecs, utils)
  - tests/                Aiken tests

Target modules:
- Endpoint: endpoint state, verification, and execution state machine
- ULN302 Send/Receive: message libraries and config handling
- Executor: commit-and-execute flow bridging verification to endpoint execution
- DVN: quorum-based verification and job assignment
- Shared: packet/header codecs, types, and constants

This is an initial scaffold to establish the project layout and shared types/codec. Subsequent commits will add full validator logic for Endpoint, ULN302, Executor, and DVN.
  
# LayerZero V2 on Cardano (Aiken)

This folder contains the Cardano (Aiken) implementation of the core LayerZero V2 components, adapted to the eUTXO model:
- Endpoint
- ULN302 MessageLib (Send, Receive)
- Executor
- DVN

Status
- Scaffold and shared modules exist and compile (aiken check).
- Packet V1 header codec matches EVM fixed-width layout: version(1) + nonce(u64=8) + srcEid(u32=4) + sender(bytes32) + dstEid(u32=4) + receiver(bytes32 padded from address20) => 81 bytes.
- Tests cover: codec hashing/layout/parse, ULN302 Receive header+attestation gating, DVN Execute quorum, Endpoint nonce/executable gating, and ULN302 Send outbound instruction validation.

Architecture overview
- State is modeled via UTXOs:
  - Endpoint Global UTXO: holds localEid and platform-level settings.
  - Per-Channel UTXOs: one per (origin, receiver) tracking inbound nonce and execution flags for concurrency.
  - ULN302 Config UTXOs: per-oapp per-dstEid configs for ULN and Executor, set via SetConfig calls.
  - DVN State UTXO: signer set, quorum, and replay map anchoring.
  - Verification/Attestation UTXOs: created by DVN/ReceiveLib to enable execution by Executor.
- Off-chain roles:
  - OApp sends messages via ULN302 Send, producing an outbound instruction UTXO and fee outputs.
  - DVN watchers pick up jobs, attest and produce verification UTXOs based on quorum.
  - Executor watchers commit-and-execute messages once Endpoint and ULN verification conditions are satisfied.
- Fees:
  - Modeled as lovelace on specific outputs; precise distribution to DVN/Executor is performed by off-chain submitters.

UTXO schemas (InlineDatum)
- AttestationDatum (used by DVN and ReceiveUln302 tests):
  - constructor index 0 with fields:
    - header_hash: ByteArray
    - payload_hash: ByteArray
    - signer_count: Int
- OutboundDatum (used by ULN302 Send tests):
  - constructor index 0 with fields:
    - header: ByteArray (must be 81 bytes for PacketV1)
    - payload: ByteArray
    - options_len: Int

Core flows
1) Send (ULN302 Send)
   - Input: OApp + options
   - Output: Outbound instruction UTXO with serialized header + payload, along with fee outputs for DVN/Executor workers.
   - Config: Uses ExecutorConfig and UlnConfig resolved per oapp/dstEid. Options are split similar to EVM.
   - Validation (current): presence of OutboundDatum with header length 81 and options_len matching the redeemer’s options length.

2) Verify (ULN302 Receive + Endpoint)
   - ReceiveUln302.assertHeader(header, localEid) checks version and dstEid.
   - DVN quorum attests to (headerHash, payloadHash), producing verification UTXOs.
   - Endpoint Verify consumes verification UTXO to mark channel nonce as verifiable/executable for the payload hash.

3) Execute (Executor)
   - If executable, consume verification and call Endpoint.lzReceive to finalize execution and update nonce state.
   - Emits native drops as specified in options by constructing appropriate outputs.

Data types and codecs
- Types: see aiken/lib/layerzero/types.ak for Eid, Address20/32, Nonce, Origin, Guid, configs, AttestationDatum, OutboundDatum.
- Codec: see aiken/lib/layerzero/codec.ak for Packet V1 header encoder, payload hashing, and helpers.
- Header v1 is byte-for-byte compatible with EVM’s PacketV1Codec.sol.

Updated semantics (aligned with EVM/altVM)
- ULN302 Receive
  - Quorum is sourced from the DVN datum via a reference input (alongside the signer set). Confirmations are enforced from the Receive config datum.
  - Requires both AttestationDatum (header_hash, payload_hash) and a SigsDatum with signatures and pubs that are unique and members of the DVN signer-set.
  - Requires an atomic Endpoint.Verify output for the same (receiver, prev_nonce) in the same transaction.

- ULN302 Send
  - Requires an OutboundDatum inline datum with header length 81 and options length matching the redeemer’s options.
  - Requires fee outputs to both configured recipients (executor_fee_vkh and dvn_fee_vkh) from the Send config datum.

- Executor (CommitAndExecute)
  - Requires exactly one Endpoint channel input at prev nonce with executed=True and the corresponding output at current nonce with executed=False (atomic LzReceive transition).
  - Requires a fee output to the configured executor_fee_vkh and covers native_drops with total lovelace in outputs.

- DVN
  - Stores signer set and quorum in DvnDatum with an admin VKH for updates.
  - Multisig uses Ed25519 verification on message = blake2b_256(header_hash || payload_hash) with unique signers and membership enforced.

Notes
- DVN signatures use Ed25519 multisig with configurable quorum; mapping to Cardano signatures will be enforced via redeemer signatures and datum state.
- Per-(origin, receiver) channel UTXOs maximize concurrency and avoid global bottlenecks.
- Endpoint and Receive library “view” functions are modeled by datum-driven states that off-chain components can query.

Next steps
- Flesh out Endpoint validator to update per-channel nonce and executable state.
- Implement ULN302 Send/Receive config set/get and verification quorum checks.
- Implement DVN signer management, job assignment, and attestation UTXO creation.
- Implement Executor commit-and-execute state transitions and native drops output shaping.
- Extend tests: DVN quorum satisfied/not, endpoint nonce monotonicity, and end-to-end header->verify gating.

Security and compatibility
- No keys or secrets are embedded in code; off-chain components sign and submit.
- Packet header layout and payload hashing are aligned with EVM to preserve cross-chain compatibility.
