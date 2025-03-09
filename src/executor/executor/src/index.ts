import { config as dotenvConfig } from "dotenv";
import {createClient, RedisClientType} from "redis";
import {
    Account,
    Chain,
    createWalletClient,
    defineChain,
    http,
    HttpTransport,
    WalletClient
} from "viem";
import { chainConfig } from "./config";
import { privateKeyToAccount } from "viem/accounts";
import { LayerZeroExecutor } from "./LayerZeroExecutor";

dotenvConfig();

async function main() {

    // Create a wallet client for the chain defined in config
    const account = privateKeyToAccount(chainConfig.privateKey);
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
    const walletClient: WalletClient<HttpTransport, Chain, Account> = createWalletClient({
        chain: chain,
        transport: http(chainConfig.rpc),
        account,
    });

    const redisClient: RedisClientType<any, any>  = createClient({
        url: process.env.REDIS_URL!,
    });
    await redisClient.connect();

    const executor = new LayerZeroExecutor(walletClient, redisClient);
    executor.start();

    console.log("LayerZero Executor is now listening for events from Redis...");
    process.stdin.resume();
}

main().catch((e) => console.error(e));
