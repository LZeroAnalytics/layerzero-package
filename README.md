# LayerZero Kurtosis package

This is a LayerZero package developed by [Bloctopus](https://www.bloctopus.io) that facilitates cross-chain message execution and verification using LayerZero V2. The package includes both on-chain and off-chain components for message verification and execution.

This package enables:

1. Cross-chain message execution using a decentralized executor.
2. Verification of messages using a Decentralized Verifier Network (DVN).
3. Listening for LayerZero events and processing them for verification.
4. Integration with Redis for event-driven execution.

## Quickstart

### Prerequisites

1. [Install Docker & start the Docker Daemon if you haven't done so already][docker-installation]
2. [Install the Kurtosis CLI, or upgrade it to the latest version if it's already installed][kurtosis-cli-installation]
3. Deploy at least two LayerZero compatible forked networks with funded accounts on each chain and reliable RPC access

### Configuration

This package is parameterizable using a YAML or JSON configuration file. Below is an example:

```yaml
networks:
  - name: ethereum
    chain_id: "3151908"
    rpc: https://59e53610a5ef41a3bc5a0e875b4e88f2-rpc.dev.lzeroanalytics.com
    endpoint: 0x1a44076050125825900e736c501f859c50fE728c
    trusted_send_lib: 0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1
    trusted_receive_lib: 0xc02Ab410f0734EFa3F14628780e6e695156024C2
    trusted_receive_lib_view: 0xc02Ab410f0734EFa3F14628780e6e695156024C2
    endpoint_view: 0x1a44076050125825900e736c501f859c50fE728c
    eid: "30101"
    exec_fee: "10000000000000000"
    private_key: 0xbcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31
  - name: arbitrum
    chain_id: "3151910"
    rpc: https://d420dda0303c431ab3fdd6a8e63d0711-rpc.dev.lzeroanalytics.com
    endpoint: 0x1a44076050125825900e736c501f859c50fE728c
    trusted_send_lib: 0x975bcD720be66659e3EB3C0e4F1866a3020E493A
    trusted_receive_lib: 0x7B9E184e07a6EE1aC23eAe0fe8D6Be2f663f05e6
    trusted_receive_lib_view: 0x7B9E184e07a6EE1aC23eAe0fe8D6Be2f663f05e6
    endpoint_view: 0x1a44076050125825900e736c501f859c50fE728c
    eid: "30110"
    exec_fee: "10000000000000000"
    private_key: 0xbcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31
```

### Parameter Descriptions

- `name`: Name of the blockchain network (arbitrary).
- `chain_id`: Chain ID of the network.
- `rpc`: RPC endpoint.
- `endpoint`: LayerZero Endpoint contract address.
- `trusted_send_lib`: Address of the send library.
- `trusted_receive_lib`: Address of the receive library.
- `trusted_receive_lib_view`: View contract for the receive library.
- `endpoint_view`: Endpoint view contract.
- `eid`: LayerZero endpoint ID.
- `exec_fee`: Execution fee in wei.
- `private_key`: Private key for transaction signing.

## Debugging

Retrieve logs:

```bash
kurtosis service logs my-enclave my-service
```

## License

This project is licensed under the MIT License.

## Contact & Support

For issues, feature requests, or contributions, please open an issue or submit a pull request on GitHub.

[docker-installation]: https://docs.docker.com/get-docker/
[kurtosis-cli-installation]: https://docs.kurtosis.com/install
[kurtosis-repo]: https://github.com/kurtosis-tech/kurtosis
[package-reference]: https://docs.kurtosis.com/advanced-concepts/packages