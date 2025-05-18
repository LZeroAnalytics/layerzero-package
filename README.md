# LayerZero Kurtosis package

This is a LayerZero package developed by [Bloctopus](https://www.bloctopus.io) that facilitates cross-chain message execution and verification using LayerZero V2. The package includes both on-chain and off-chain components for message verification and execution.

This package does the following:

1. Deploy simple DVN and Executor contracts into the specified networks
2. Spin up a DVN off-chain component for each specified connection
3. Spin up an Executor off-chain component for each specified connection

## Get started

### Prerequisites

1. [Install Docker & start the Docker Daemon if you haven't done so already][docker-installation]
2. [Install the Kurtosis CLI, or upgrade it to the latest version if it's already installed][kurtosis-cli-installation]
3. Deploy at least two LayerZero compatible forked networks with funded accounts on each chain and reliable RPC access. These networks need to be remote networks and cannot be running on localhost. (See [Coming Soon](#coming-soon) section)

### Configuration

This package is parameterizable using a YAML or JSON configuration file.
Below is an example which connects two networks that were created through the [Bloctopus](https://www.bloctopus.io) platform:


```yaml
networks:
  - name: ethereum
    chain_id: "3151908"
    rpc: https://769aebebe72d4b069840e92ce9b06fad-rpc.dev.lzeroanalytics.com
    endpoint: 0x1a44076050125825900e736c501f859c50fE728c
    trusted_send_lib: 0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1
    trusted_receive_lib: 0xc02Ab410f0734EFa3F14628780e6e695156024C2
    eid: "30101"
    private_key: 0xbcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31
  - name: arbitrum
    chain_id: "3151910"
    rpc: https://ebc3f5fcc4ce423ba43b837872b43941-rpc.dev.lzeroanalytics.com
    endpoint: 0x1a44076050125825900e736c501f859c50fE728c
    trusted_send_lib: 0x975bcD720be66659e3EB3C0e4F1866a3020E493A
    trusted_receive_lib: 0x7B9E184e07a6EE1aC23eAe0fe8D6Be2f663f05e6
    eid: "30110"
    private_key: 0xbcdf20249abf0ed6d944c0288fad489e33f66b3960d9e6229c1cd214ed3bbe31
connections:
  - from: ethereum
    to: arbitrum
    exec_fee: "10000000000000000" # in wei
    dvn_fee: "0" # in wei
```

For simplicity, you can also specify a `type` for each network which will automatically use known values for 
`endpoint`, `trusted_send_lib`, `trusted_receive_lib`, `chain_id` and `eid`.
Make sure you still specify `name`, `rpc`, and `private_key`. Below are the supported known networks:

```text
ethereum_mainnet
ethereum_sepolia
ethereum_holesky
arbitrum_mainnet
arbitrum_sepolia
optimism_mainnet
optimism_sepolia
base_mainnet
base_sepolia
```

### Running the package
To run the package, use the command below.
You can use [network_remote.yaml](network_remote.yaml) or [network_custom.yaml](network_custom.yaml) as sample files.
```bash
kurtosis run --enclave <enclave-name> github.com/LZeroAnalytics/layerzero-package --args-file <config file>
```

To shut down the enclave, you can run:

```bash
kurtosis enclave rm -f <enclave-name>
```

To retrieve logs from any service, you can run:
```bash
kurtosis service logs <enclave-name> <service-name>
```

## Features
1. Automatic deployment of LayerZero Endpoint and MessageLib contracts for networks that don't have them
2. Support for chains that LayerZero doesn't currently support

## Coming Soon
1. Running fully local deployments including all the required forked networks

## License

This project is licensed under the MIT License.

## Contact & Support

For issues, feature requests, or contributions, please open an issue or submit a pull request on GitHub.

[docker-installation]: https://docs.docker.com/get-docker/
[kurtosis-cli-installation]: https://docs.kurtosis.com/install
[kurtosis-repo]: https://github.com/kurtosis-tech/kurtosis
[package-reference]: https://docs.kurtosis.com/advanced-concepts/packages
