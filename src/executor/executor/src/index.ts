// src/index.ts
import { config as dotenvConfig } from "dotenv";
import { createClient } from "redis";
import {
    Account,
    Chain,
    createPublicClient,
    createWalletClient,
    defineChain,
    http,
    HttpTransport,
    WalletClient
} from "viem";
import { chainConfig } from "./config";
import { privateKeyToAccount } from "viem/accounts";
import { LayerZeroExecutor } from "./LayerZeroExecutor";
import { LZRawEvent, LZVerifiedEvent} from "./types";
import { abi as receiveLibABI } from "./abis/ReceiveUln302";

// Load environment variables
dotenvConfig();

// Create a wallet client for the chain defined in config
const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);
const chain = defineChain({
    id: chainConfig.chainId,
    name: chainConfig.name,
    nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
    rpcUrls: {
        default: {
            http: [chainConfig.rpc],
        },
    }
});
const client: WalletClient<HttpTransport, Chain, Account> = createWalletClient({
    chain: chain,
    transport: http(chainConfig.rpc),
    account,
});

const publicClient = createPublicClient({
    chain: chain,
    transport: http(process.env.RPC_URL!),
});

async function main() {
    const executor = new LayerZeroExecutor(chainConfig, client);
    executor.start();

    const redisSub = createClient({
        url: process.env.BROKER_URL!,
    });
    await redisSub.connect();

    const channels = process.env.COMMITTER_CHANNELS
        ? process.env.COMMITTER_CHANNELS.split(",").map(ch => ch.trim())
        : [];

    if (channels.length === 0) {
        console.error("No committer channels specified. Please set COMMITTER_CHANNELS in your env.");
        process.exit(1);
    }

    for (const channel of channels) {
        await redisSub.subscribe(channel, (message) => {
            console.log(`Executor received raw event from channel ${channel}:`, message);
            try {
                const event: LZRawEvent = JSON.parse(message);
                executor.addRawEvent(event);
            } catch (e) {
                console.error("Failed to parse event:", e);
            }
        });
    }

    publicClient.watchContractEvent({
        address: chainConfig.trustedReceiveLib,
        abi: receiveLibABI,
        eventName: "PayloadVerified",
        onLogs: async (logs) => {
            for (const log of logs) {
                console.log("PayloadVerified event detected: ", log);
                // Extract event parameters.
                // The ABI provides: dvn, header, confirmations, proofHash.
                const header = log.args.header as `0x${string}`;
                const proofHash = log.args.proofHash as `0x${string}`;
                const confirmations = log.args.confirmations as bigint;

                // Build an LZMessageEvent object.
                const eventObj: LZVerifiedEvent = {
                    type: "verified",
                    header: header,
                    confirmations: confirmations,
                    transactionHash: log.transactionHash,
                };

                executor.addVerifiedEvent(eventObj);
            }
        },
    });

    console.log("LayerZero Executor is now listening for events from Redis...");
    process.stdin.resume();
}

main().catch((e) => console.error(e));
