import {createPublicClient, defineChain, http} from "viem";
import { config as dotenvConfig } from "dotenv";
import { createClient, RedisClientType } from "redis";
import { PacketSentWatcher } from "./watchers/PacketSentWatcher";
import {PayloadVerifiedHandler} from "./handlers/PayloadVerifiedHandler";
import {config} from "./config";
import {PacketVerifiedHandler} from "./handlers/PacketVerifedHandler";

dotenvConfig();

async function main() {

    const sourceChain = defineChain({
        id: Number(config.networkA.chainId),
        name: config.networkA.name,
        nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
        rpcUrls: {
            default: {
                http: [config.networkA.rpc],
            },
        }
    });

    const destinationChain = defineChain({
        id: Number(config.networkB.chainId),
        name: config.networkB.name,
        nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
        rpcUrls: {
            default: {
                http: [config.networkB.rpc],
            },
        }
    });

    const sourceClient = createPublicClient({
        chain: sourceChain,
        transport: http(config.networkA.rpc),
    });

    const destinationClient = createPublicClient({
        chain: destinationChain,
        transport: http(config.networkB.rpc),
    });

    const redisSubscribeClient: RedisClientType<any, any> = createClient({
        url: process.env.REDIS_URL!,
    });
    await redisSubscribeClient.connect();

    const redisPublishClient: RedisClientType<any, any> = redisSubscribeClient.duplicate();
    await redisPublishClient.connect();

    // Create watchers for both networks (bidirectional)
    const packetSentWatcherA = new PacketSentWatcher(sourceClient, redisPublishClient, config.networkA.endpoint, config.networkA.executor);
    const packetSentWatcherB = new PacketSentWatcher(destinationClient, redisPublishClient, config.networkB.endpoint, config.networkB.executor);
    const payloadVerifiedHandlerA = new PayloadVerifiedHandler(sourceClient, redisSubscribeClient, redisPublishClient);
    const payloadVerifiedHandlerB = new PayloadVerifiedHandler(destinationClient, redisSubscribeClient, redisPublishClient);
    const packetVerifiedHandlerA = new PacketVerifiedHandler(sourceClient, redisSubscribeClient, redisPublishClient);
    const packetVerifiedHandlerB = new PacketVerifiedHandler(destinationClient, redisSubscribeClient, redisPublishClient);

    // Start the components for handling each step of the workflow
    packetSentWatcherA.start();
    packetSentWatcherB.start();
    payloadVerifiedHandlerA.start();
    payloadVerifiedHandlerB.start();
    packetVerifiedHandlerA.start();
    packetVerifiedHandlerB.start();

    console.log("All event handlers started. Listening for events...");
    process.stdin.resume();
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});