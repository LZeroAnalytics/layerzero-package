import {configDotenv} from "dotenv";

configDotenv();

export interface ChainConfig {
    name: string;
    rpc: string;
    endpoint: `0x${string}`;
    endpointView: `0x${string}`;
    trustedSendLib: `0x${string}`;
    trustedReceiveLib: `0x${string}`;
    trustedReceiveLibView: `0x${string}`;
    eid: number;
    executor: `0x${string}`;
}

export const chainConfig: ChainConfig = {
    name: process.env.CHAIN_NAME || "local",
    rpc: process.env.RPC_URL || "http://127.0.0.1:8545",
    endpoint: process.env.ENDPOINT as `0x${string}`,
    endpointView: process.env.ENDPOINT_VIEW as `0x${string}`,
    trustedSendLib: process.env.TRUSTED_SEND_LIB as `0x${string}`,
    trustedReceiveLib: process.env.TRUSTED_RECEIVE_LIB as `0x${string}`,
    trustedReceiveLibView: process.env.TRUSTED_RECEIVE_LIB_VIEW as `0x${string}`,
    eid: parseInt(process.env.EID || "0"),
    executor: process.env.EXECUTOR as `0x${string}`,
};
