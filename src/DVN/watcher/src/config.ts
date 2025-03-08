import {configDotenv} from "dotenv";

configDotenv();

export interface ChainConfig {
    name: string;
    rpc: string;
    chainId: number,
    endpoint: `0x${string}`;
    endpointView: `0x${string}`;
    trustedSendLib: `0x${string}`;
    trustedReceiveLib: `0x${string}`;
    trustedReceiveLibView: `0x${string}`;
    eid: number;
    dvn: `0x${string}`;
}

export const sourceConfig: ChainConfig = {
    name: process.env.SRC_NAME || "local",
    chainId: Number(process.env.SRC_CHAIN_ID) || 1,
    rpc: process.env.SRC_RPC_URL || "http://127.0.0.1:8545",
    endpoint: process.env.SRC_ENDPOINT as `0x${string}`,
    endpointView: process.env.SRC_ENDPOINT_VIEW as `0x${string}`,
    trustedSendLib: process.env.SRC_TRUSTED_SEND_LIB as `0x${string}`,
    trustedReceiveLib: process.env.SRC_TRUSTED_RECEIVE_LIB as `0x${string}`,
    trustedReceiveLibView: process.env.SRC_TRUSTED_RECEIVE_LIB_VIEW as `0x${string}`,
    eid: parseInt(process.env.SRC_EID || "0"),
    dvn: process.env.DST_DVN_ADDR as `0x${string}`,
};

export const destinationConfig: ChainConfig = {
    name: process.env.DST_NAME || "local",
    chainId: Number(process.env.DST_CHAIN_ID) || 1,
    rpc: process.env.DST_RPC_URL || "http://127.0.0.1:8545",
    endpoint: process.env.DST_ENDPOINT as `0x${string}`,
    endpointView: process.env.DST_ENDPOINT_VIEW as `0x${string}`,
    trustedSendLib: process.env.DST_TRUSTED_SEND_LIB as `0x${string}`,
    trustedReceiveLib: process.env.DST_TRUSTED_RECEIVE_LIB as `0x${string}`,
    trustedReceiveLibView: process.env.DST_TRUSTED_RECEIVE_LIB_VIEW as `0x${string}`,
    eid: parseInt(process.env.DST_EID || "0"),
    dvn: process.env.DST_DVN_ADDR as `0x${string}`,
};
