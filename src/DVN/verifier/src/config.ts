import {configDotenv} from "dotenv";

configDotenv();

export interface NetworkConfig {
    name: string;
    rpc: string;
    chainId: number;
    trustedReceiveLib: `0x${string}`;
    dvnAddresses: `0x${string}`[];
    privateKeys: `0x${string}`[];
    dvnNames: string[];
}

export interface DVNConfig {
    networkA: NetworkConfig;
    networkB: NetworkConfig;
    useAllDVNs: boolean;
}

function parseNetworkConfig(prefix: 'NETWORK_A' | 'NETWORK_B'): NetworkConfig {
    const dvnAddresses = (process.env[`${prefix}_DVN_ADDRESSES`] || "")
        .split(',')
        .map(addr => addr.trim() as `0x${string}`)
        .filter(addr => addr && addr.length > 0);
    
    const privateKeys = (process.env[`${prefix}_DVN_PRIVATE_KEYS`] || "")
        .split(',')
        .map(key => key.trim() as `0x${string}`)
        .filter(key => key && key.length > 0);
    
    const dvnNames = (process.env[`${prefix}_DVN_NAMES`] || "")
        .split(',')
        .map(name => name.trim())
        .filter(name => name !== "");
    
    return {
        name: process.env[`${prefix}_NAME`] || "unknown",
        chainId: Number(process.env[`${prefix}_CHAIN_ID`]) || 1,
        rpc: process.env[`${prefix}_RPC_URL`] || "http://127.0.0.1:8545",
        trustedReceiveLib: process.env[`${prefix}_TRUSTED_RECEIVE_LIB`] as `0x${string}`,
        dvnAddresses,
        privateKeys,
        dvnNames,
    };
}

function parseConfig(): DVNConfig {
    const networkA = parseNetworkConfig('NETWORK_A');
    const networkB = parseNetworkConfig('NETWORK_B');
    
    return {
        networkA,
        networkB,
        useAllDVNs: process.env.USE_ALL_DVNS?.toLowerCase() === 'true',
    };
}

export const config: DVNConfig = parseConfig();
