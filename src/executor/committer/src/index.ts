import {Account, defineChain, http, HttpTransport, WalletClient, Chain, createWalletClient} from "viem";
import { config as dotenvConfig } from "dotenv";
import { LayerZeroCommitter } from "./LayerZeroCommitter";
import {createClient, RedisClientType} from "redis";
import {chainConfig} from "./config";
import {privateKeyToAccount} from "viem/accounts";

dotenvConfig();

async function main() {

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

    const account = privateKeyToAccount(chainConfig.privateKey);

    const walletClient: WalletClient<HttpTransport, Chain, Account> = createWalletClient({
        chain,
        transport: http(chainConfig.rpc),
        account,
    });

    const redisSubscribeClient: RedisClientType<any, any> = createClient({
        url: process.env.REDIS_URL!,
    });
    await redisSubscribeClient.connect();

    const redisPublishClient: RedisClientType<any, any> = redisSubscribeClient.duplicate();
    redisPublishClient.connect();

    const committer = new LayerZeroCommitter(walletClient, redisSubscribeClient, redisPublishClient);

    committer.start();

    console.log("LayerZero Committer is now listening for events to commit...");
    process.stdin.resume();
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});