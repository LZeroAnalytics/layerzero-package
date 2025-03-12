import {config as dotenvConfig} from "dotenv";

dotenvConfig();

export interface ChainConfig {
    name: string;
    rpc: string;
    chainId: number,
    privateKey: `0x${string}`;
}

export const chainConfig: ChainConfig = {
    name: process.env.DST_NAME || "local",
    chainId: Number(process.env.DST_CHAIN_ID) || 1,
    rpc: process.env.DST_RPC_URL || "http://127.0.0.1:8545",
    privateKey: process.env.DST_PRIVATE_KEY as `0x${string}`,
};
