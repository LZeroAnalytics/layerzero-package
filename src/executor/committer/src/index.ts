// src/index.ts
import {createPublicClient, defineChain, http} from "viem";
import {mainnet} from "viem/chains";
import { config as dotenvConfig } from "dotenv";
import { LayerZeroCommitter, LZMessageEvent } from "./LayerZeroCommitter";
import { createClient } from "redis";

// Load environment variables from .env file.
dotenvConfig();

async function main() {

    const chain = defineChain({
        id: Number(process.env.CHAIN_ID!),
        name: process.env.NAME!,
        nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
        rpcUrls: {
            default: {
                http: [process.env.RPC_URL!],
            },
        }
    });

    const client = createPublicClient({
        chain: chain,
        transport: http(process.env.RPC_URL!),
    });

    const redisClient = createClient({
        url: process.env.BROKER_URL!,
    });
    await redisClient.connect();

    const networkName = process.env.NAME!;

    const committer = new LayerZeroCommitter(client);

    // Replace to convert big int to string and using stringify
    const replacer = (key: string, value: any): any => {
        return typeof value === 'bigint' ? value.toString() : value;
    };

    // Start watching for events.
    const stop = committer.start(async (event: LZMessageEvent) => {
        console.log("Committer received event:", event.transactionHash);
        await redisClient.publish(networkName, JSON.stringify(event, replacer));
    });

    console.log("LayerZero Committer is now listening for events and publishing to Redis...");
    process.stdin.resume();
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});