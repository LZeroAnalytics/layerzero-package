import {createPublicClient, defineChain, http} from "viem";
import { config as dotenvConfig } from "dotenv";
import { createClient, RedisClientType } from "redis";
import { PacketSentWatcher } from "./watchers/PacketSentWatcher";
import { JobAssignedWatcher } from "./watchers/JobAssignedWatcher";
import { ReceiveLibHandler } from "./handlers/ReceiveLibHandler";

// Load environment variables from .env file.
dotenvConfig();

async function main() {

    const chain = defineChain({
        id: Number(process.env.CHAIN_ID!),
        name: process.env.NAME!,
        nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
        rpcUrls: {
            default: {
                http: [process.env.RPC_URL!],
            },
        }
    });

    const client = createPublicClient({
        chain: chain,
        transport: http(process.env.RPC_URL!),
    });

    const redisClient: RedisClientType<any, any> = createClient({
        url: process.env.BROKER_URL!,
    });
    await redisClient.connect();

    const packetSentWatcher = new PacketSentWatcher(client, redisClient);
    const jobAssignedWatcher = new JobAssignedWatcher(client, redisClient);
    const receiveLibHandler = new ReceiveLibHandler(client, redisClient);

    // Start the components for handling each step of the workflow
    packetSentWatcher.start();
    jobAssignedWatcher.start();
    receiveLibHandler.start();

    console.log("All event handlers started. Listening for events...");
    process.stdin.resume();
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});