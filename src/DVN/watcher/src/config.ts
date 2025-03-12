import {configDotenv} from "dotenv";

configDotenv();

export interface SourceChainConfig {
    name: string;
    rpc: string;
    chainId: number,
    endpoint: `0x${string}`;
    trustedSendLib: `0x${string}`;
    dvn: `0x${string}`;
}

export interface DestinationChainConfig {
    name: string;
    rpc: string;
    chainId: number,
    endpoint: `0x${string}`;
}

export const sourceConfig: SourceChainConfig = {
    name: process.env.SRC_NAME || "local",
    chainId: Number(process.env.SRC_CHAIN_ID) || 1,
    rpc: process.env.SRC_RPC_URL || "http://127.0.0.1:8545",
    endpoint: process.env.SRC_ENDPOINT as `0x${string}`,
    trustedSendLib: process.env.SRC_TRUSTED_SEND_LIB as `0x${string}`,
    dvn: process.env.SRC_DVN_ADDR as `0x${string}`,
};

export const destinationConfig: DestinationChainConfig = {
    name: process.env.DST_NAME || "local",
    chainId: Number(process.env.DST_CHAIN_ID) || 1,
    rpc: process.env.DST_RPC_URL || "http://127.0.0.1:8545",
    endpoint: process.env.DST_ENDPOINT as `0x${string}`,
};
