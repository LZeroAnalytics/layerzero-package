import {configDotenv} from "dotenv";

configDotenv();

export interface NetworkConfig {
    name: string;
    rpc: string;
    chainId: number,
    endpoint: `0x${string}`;
    trustedSendLib: `0x${string}`;
}

export interface WatcherConfig {
    networkA: NetworkConfig;
    networkB: NetworkConfig;
}

function parseNetworkConfig(prefix: 'NETWORK_A' | 'NETWORK_B'): NetworkConfig {
    return {
        name: process.env[`${prefix}_NAME`] || "unknown",
        chainId: Number(process.env[`${prefix}_CHAIN_ID`]) || 1,
        rpc: process.env[`${prefix}_RPC_URL`] || "http://127.0.0.1:8545",
        endpoint: process.env[`${prefix}_ENDPOINT`] as `0x${string}`,
        trustedSendLib: process.env[`${prefix}_TRUSTED_SEND_LIB`] as `0x${string}`,
    };
}

export const config: WatcherConfig = {
    networkA: parseNetworkConfig('NETWORK_A'),
    networkB: parseNetworkConfig('NETWORK_B'),
};
