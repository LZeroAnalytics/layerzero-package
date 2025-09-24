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
import { config } from "./config";
import { privateKeyToAccount } from "viem/accounts";
import { LayerZeroExecutor } from "./LayerZeroExecutor";

dotenvConfig();

async function main() {

    // Create wallet clients for both networks (bidirectional)
    const accountA = privateKeyToAccount(config.networkA.privateKey);
    const accountB = privateKeyToAccount(config.networkB.privateKey);
    
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

    const redisClient: RedisClientType<any, any>  = createClient({
        url: process.env.REDIS_URL!,
    });
    await redisClient.connect();

    // Create executors for both networks
    const executorA = new LayerZeroExecutor(walletClientA, redisClient);
    const executorB = new LayerZeroExecutor(walletClientB, redisClient);
    
    executorA.start();
    executorB.start();

    console.log("LayerZero Executor is now listening for events from Redis...");
    process.stdin.resume();
}

main().catch((e) => console.error(e));
