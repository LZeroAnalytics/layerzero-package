import {configDotenv} from "dotenv";

configDotenv();

export interface ChainConfig {
    name: string;
    rpc: string;
    chainId: number,
    trustedReceiveLib: `0x${string}`;
    dvn: `0x${string}`;
    privateKey: `0x${string}`;
}

export const chainConfig: ChainConfig = {
    name: process.env.NAME || "local",
    chainId: Number(process.env.CHAIN_ID) || 1,
    rpc: process.env.RPC_URL || "http://127.0.0.1:8545",
    trustedReceiveLib: process.env.TRUSTED_RECEIVE_LIB as `0x${string}`,
    dvn: process.env.DVN_ADDR as `0x${string}`,
    privateKey: process.env.PRIVATE_KEY as `0x${string}`,
};
