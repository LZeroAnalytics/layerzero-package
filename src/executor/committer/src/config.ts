import {config as dotenvConfig} from "dotenv";

dotenvConfig();

export interface ChainConfig {
    endpoint: `0x${string}`;
    trustedSendLib: `0x${string}`;
    executor: `0x${string}`;
    eid: number;
}

export const chainConfig: ChainConfig = {
    endpoint: process.env.ENDPOINT as `0x${string}`,
    trustedSendLib: process.env.TRUSTED_SEND_LIB as `0x${string}`,
    executor: process.env.EXECUTOR as `0x${string}`,
    eid: parseInt(process.env.EID || "0"),
};
