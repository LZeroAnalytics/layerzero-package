import { config as dotenvConfig } from "dotenv";
import { createClient } from "redis";
import {
    createWalletClient,
    defineChain,
    http,
    WalletClient,
    Chain,
    Account,
    HttpTransport,
} from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { chainConfig } from "./config";
import { DVN } from "./DVN";
import { LZMessageEvent } from "./types";

dotenvConfig();

// Create a wallet client using the DVN private key.
const dvnPrivateKey = process.env.DVN_PRIVATE_KEY as `0x${string}`;
const account = privateKeyToAccount(dvnPrivateKey);
const chain = defineChain({
    id: chainConfig.chainId,
    name: chainConfig.name,
    nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
    rpcUrls: {
        default: {
            http: [chainConfig.rpc],
        },
    },
});
const client: WalletClient<HttpTransport, Chain, Account> = createWalletClient({
    chain,
    transport: http(chainConfig.rpc),
    account,
});

async function main() {
    const dvn = new DVN(client);

    const redisSub = createClient({
        url: process.env.BROKER_URL!,
    });
    await redisSub.connect();

    const channels = process.env.COMMITTER_CHANNELS
        ? process.env.COMMITTER_CHANNELS.split(",").map((ch) => ch.trim())
        : [];

    if (channels.length === 0) {
        console.error("No committer channels specified. Please set COMMITTER_CHANNELS in your env.");
        process.exit(1);
    }

    for (const channel of channels) {
        await redisSub.subscribe(channel, (message) => {
            console.log(`DVN received event from channel ${channel}:`, message);
            try {
                const event: LZMessageEvent = JSON.parse(message);
                dvn.processEvent(event).catch((e) => {
                    console.error("Error processing DVN event:", e);
                });
            } catch (e) {
                console.error("Failed to parse DVN event:", e);
            }
        });
    }

    console.log("DVN is now listening for events from Redis...");
    process.stdin.resume();
}

main().catch((e) => {
    console.error(e);
    process.exit(1);
});