import {config as dotenvConfig} from "dotenv";

dotenvConfig();

export interface ChainConfig {
    name: string;
    rpc: string;
    chainId: number,
    privateKey: `0x${string}`;
}

export const chainConfig: ChainConfig = {
    name: process.env.NAME || "local",
    chainId: Number(process.env.CHAIN_ID) || 1,
    rpc: process.env.RPC_URL || "http://127.0.0.1:8545",
    privateKey: process.env.DST_PRIVATE_KEY as `0x${string}`,
};
