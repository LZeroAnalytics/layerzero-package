import {createPublicClient, defineChain, http} from "viem";
import { config as dotenvConfig } from "dotenv";
import { createClient, RedisClientType } from "redis";
import { PacketSentWatcher } from "./watchers/PacketSentWatcher";
import {PayloadVerifiedHandler} from "./handlers/PayloadVerifiedHandler";
import {destinationConfig, sourceConfig} from "./config";
import {PacketVerifiedHandler} from "./handlers/PacketVerifedHandler";

dotenvConfig();

async function main() {

    const sourceChain = defineChain({
        id: Number(sourceConfig.chainId),
        name: sourceConfig.name,
        nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
        rpcUrls: {
            default: {
                http: [sourceConfig.rpc],
            },
        }
    });

    const destinationChain = defineChain({
        id: Number(destinationConfig.chainId),
        name: destinationConfig.name,
        nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
        rpcUrls: {
            default: {
                http: [destinationConfig.rpc],
            },
        }
    });

    const sourceClient = createPublicClient({
        chain: sourceChain,
        transport: http(sourceConfig.rpc),
    });

    const destinationClient = createPublicClient({
        chain: destinationChain,
        transport: http(destinationConfig.rpc),
    });

    const redisSubscribeClient: RedisClientType<any, any> = createClient({
        url: process.env.REDIS_URL!,
    });
    await redisSubscribeClient.connect();

    const redisPublishClient: RedisClientType<any, any> = redisSubscribeClient.duplicate();
    await redisPublishClient.connect();

    const packetSentWatcher = new PacketSentWatcher(sourceClient, redisPublishClient);
    const payloadVerifiedHandler = new PayloadVerifiedHandler(destinationClient, redisSubscribeClient, redisPublishClient);
    const packetVerifiedHandler = new PacketVerifiedHandler(destinationClient, redisSubscribeClient, redisPublishClient);

    // Start the components for handling each step of the workflow
    packetSentWatcher.start();
    payloadVerifiedHandler.start();
    packetVerifiedHandler.start();

    console.log("All event handlers started. Listening for events...");
    process.stdin.resume();
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});