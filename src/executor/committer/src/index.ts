// src/index.ts
import { createPublicClient, http } from "viem";
import {mainnet} from "viem/chains";
import { config as dotenvConfig } from "dotenv";
import { LayerZeroCommitter, LZMessageEvent } from "./LayerZeroCommitter";
import { createClient } from "redis";

// Load environment variables from .env file.
dotenvConfig();

async function main() {
    const client = createPublicClient({
        chain: mainnet,
        transport: http(process.env.RPC_URL!),
    });

    const redisClient = createClient({
        url: process.env.BROKER_URL || "redis://redis-broker:6379",
    });
    await redisClient.connect();

    const networkName = process.env.NAME || 'layerzero';

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