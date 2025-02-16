// src/index.ts
import { config as dotenvConfig } from "dotenv";
import { createClient } from "redis";
import {Account, Chain, createWalletClient, http, HttpTransport, WalletClient} from "viem";
import { mainnet } from "viem/chains";
import { chainConfig } from "./config";
import { privateKeyToAccount } from "viem/accounts";
import { LayerZeroExecutor } from "./LayerZeroExecutor";
import { LZMessageEvent } from "./types";

// Load environment variables
dotenvConfig();

// Create a wallet client for the chain defined in config
const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);
const client: WalletClient<HttpTransport, Chain, Account> = createWalletClient({
    chain: mainnet,
    transport: http(chainConfig.rpc),
    account,
});

async function main() {
    const executor = new LayerZeroExecutor(chainConfig, client);
    executor.start();

    const redisSub = createClient({
        url: process.env.BROKER_URL || "redis://redis-broker:6379",
    });
    await redisSub.connect();

    const networkName = process.env.NAME || 'layerzero';

    // Subscribe to the Redis channel used by the committer.
    await redisSub.subscribe(networkName, (message) => {
        console.log("Executor received event from broker:", message);
        try {
            const event: LZMessageEvent = JSON.parse(message);
            executor.addEvent(event);
        } catch (e) {
            console.error("Failed to parse event:", e);
        }
    });

    console.log("LayerZero Executor is now listening for events from Redis...");
    process.stdin.resume();
}

main().catch((e) => console.error(e));
