import {createPublicClient, defineChain, http} from "viem";
import { config as dotenvConfig } from "dotenv";
import { createClient, RedisClientType } from "redis";
import { PacketSentWatcher } from "./watchers/PacketSentWatcher";
import { ReceiveLibHandler } from "./handlers/ReceiveLibHandler";
import {config} from "./config";

dotenvConfig();

async function main() {

    const networkAChain = defineChain({
        id: Number(config.networkA.chainId),
        name: config.networkA.name,
        nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
        rpcUrls: {
            default: {
                http: [config.networkA.rpc],
            },
        }
    });

    const networkBChain = defineChain({
        id: Number(config.networkB.chainId),
        name: config.networkB.name,
        nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
        rpcUrls: {
            default: {
                http: [config.networkB.rpc],
            },
        }
    });

    const networkAClient = createPublicClient({
        chain: networkAChain,
        transport: http(config.networkA.rpc),
    });

    const networkBClient = createPublicClient({
        chain: networkBChain,
        transport: http(config.networkB.rpc),
    });

    const redisSubscribeClient: RedisClientType<any, any> = createClient({
        url: process.env.REDIS_URL!,
    });
    await redisSubscribeClient.connect();

    const redisPublishClient: RedisClientType<any, any> = redisSubscribeClient.duplicate();
    await redisPublishClient.connect();

    // Create watchers for both networks (bidirectional)
    const packetSentWatcherA = new PacketSentWatcher(networkAClient, redisPublishClient, config.networkA.endpoint);
    const packetSentWatcherB = new PacketSentWatcher(networkBClient, redisPublishClient, config.networkB.endpoint);
    const receiveLibHandlerA = new ReceiveLibHandler(networkAClient, redisSubscribeClient, redisPublishClient);
    const receiveLibHandlerB = new ReceiveLibHandler(networkBClient, redisSubscribeClient, redisPublishClient);

    // Start the components for handling each step of the workflow
    packetSentWatcherA.start();
    packetSentWatcherB.start();
    receiveLibHandlerA.start();
    receiveLibHandlerB.start();

    console.log("All event handlers started. Listening for events...");
    process.stdin.resume();
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});