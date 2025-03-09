import {createPublicClient, defineChain, http} from "viem";
import { config as dotenvConfig } from "dotenv";
import { createClient, RedisClientType } from "redis";
import { PacketSentWatcher } from "./watchers/PacketSentWatcher";
import { JobAssignedWatcher } from "./watchers/JobAssignedWatcher";
import {PayloadVerifiedHandler} from "./handlers/PayloadVerifiedHandler";
import {destinationConfig, sourceConfig} from "./config";

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

    const redisClient: RedisClientType<any, any> = createClient({
        url: process.env.REDIS_URL!,
    });
    await redisClient.connect();

    const packetSentWatcher = new PacketSentWatcher(sourceClient, redisClient);
    const jobAssignedWatcher = new JobAssignedWatcher(sourceClient, redisClient);
    const payloadVerifiedHandler = new PayloadVerifiedHandler(destinationClient, redisClient);
    const packetVerifiedHandler = new PayloadVerifiedHandler(destinationClient, redisClient);

    // Start the components for handling each step of the workflow
    packetSentWatcher.start();
    jobAssignedWatcher.start();
    payloadVerifiedHandler.start();
    packetSentWatcher.start();

    console.log("All event handlers started. Listening for events...");
    process.stdin.resume();
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});