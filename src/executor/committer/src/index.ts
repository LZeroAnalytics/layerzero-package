import {Account, defineChain, http, HttpTransport, WalletClient, Chain, createWalletClient} from "viem";
import { config as dotenvConfig } from "dotenv";
import { LayerZeroCommitter } from "./LayerZeroCommitter";
import {createClient, RedisClientType} from "redis";
import {config} from "./config";
import {privateKeyToAccount} from "viem/accounts";

dotenvConfig();

async function main() {

    // Create wallet clients for both networks (bidirectional)
    const chainA = defineChain({
        id: config.networkA.chainId,
        name: config.networkA.name,
        nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
        rpcUrls: {
            default: {
                http: [config.networkA.rpc],
            },
        }
    });

    const chainB = defineChain({
        id: config.networkB.chainId,
        name: config.networkB.name,
        nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
        rpcUrls: {
            default: {
                http: [config.networkB.rpc],
            },
        }
    });

    const accountA = privateKeyToAccount(config.networkA.privateKey);
    const accountB = privateKeyToAccount(config.networkB.privateKey);

    const walletClientA: WalletClient<HttpTransport, Chain, Account> = createWalletClient({
        chain: chainA,
        transport: http(config.networkA.rpc),
        account: accountA,
    });

    const walletClientB: WalletClient<HttpTransport, Chain, Account> = createWalletClient({
        chain: chainB,
        transport: http(config.networkB.rpc),
        account: accountB,
    });

    const redisSubscribeClient: RedisClientType<any, any> = createClient({
        url: process.env.REDIS_URL!,
    });
    await redisSubscribeClient.connect();

    const redisPublishClient: RedisClientType<any, any> = redisSubscribeClient.duplicate();
    redisPublishClient.connect();

    // Create committers for both networks
    const committerA = new LayerZeroCommitter(walletClientA, redisSubscribeClient, redisPublishClient);
    const committerB = new LayerZeroCommitter(walletClientB, redisSubscribeClient, redisPublishClient);

    committerA.start();
    committerB.start();

    console.log("LayerZero Committer is now listening for events to commit...");
    process.stdin.resume();
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});