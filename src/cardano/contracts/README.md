# Cardano LayerZero Contracts (Aiken)

This directory contains the Cardano eUTXO adaptations of LayerZero V2 core contracts implemented in Aiken.

Structure:
- aiken/                  Aiken project root
  - aiken.toml            Project config
  - validators/           On-chain validators (scripts)
  - lib/                  Shared libraries (types, codecs, utils)
  - tests/                Aiken tests (to be added)

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
- Basic tests for codec hashing and header layout are in tests/.

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

Core flows
1) Send (ULN302 Send)
   - Input: OApp + options
   - Output: Outbound instruction UTXO with serialized header + payload, along with fee outputs for DVN/Executor workers.
   - Config: Uses ExecutorConfig and UlnConfig resolved per oapp/dstEid. Options are split similar to EVM.

2) Verify (ULN302 Receive + Endpoint)
   - ReceiveUln302.assertHeader(header, localEid) checks version and dstEid.
   - DVN quorum attests to (headerHash, payloadHash), producing verification UTXOs.
   - Endpoint Verify consumes verification UTXO to mark channel nonce as verifiable/executable for the payload hash.

3) Execute (Executor)
   - If executable, consume verification and call Endpoint.lzReceive to finalize execution and update nonce state.
   - Emits native drops as specified in options by constructing appropriate outputs.

Data types and codecs
- Types: see aiken/lib/layerzero/types.ak for Eid, Address20/32, Nonce, Origin, Guid, configs.
- Codec: see aiken/lib/layerzero/codec.ak for Packet V1 header encoder, payload hashing, and helpers.
- Header v1 is byte-for-byte compatible with EVM’s PacketV1Codec.sol.

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
