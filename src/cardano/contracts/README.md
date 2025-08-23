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
