import {config as dotenvConfig} from "dotenv";

dotenvConfig();

export interface NetworkConfig {
    name: string;
    rpc: string;
    chainId: number,
    privateKey: `0x${string}`;
}

export interface CommitterConfig {
    networkA: NetworkConfig;
    networkB: NetworkConfig;
}

function parseNetworkConfig(prefix: 'NETWORK_A' | 'NETWORK_B'): NetworkConfig {
    return {
        name: process.env[`${prefix}_NAME`] || "unknown",
        chainId: Number(process.env[`${prefix}_CHAIN_ID`]) || 1,
        rpc: process.env[`${prefix}_RPC_URL`] || "http://127.0.0.1:8545",
        privateKey: process.env[`${prefix}_PRIVATE_KEY`] as `0x${string}`,
    };
}

export const config: CommitterConfig = {
    networkA: parseNetworkConfig('NETWORK_A'),
    networkB: parseNetworkConfig('NETWORK_B'),
};
