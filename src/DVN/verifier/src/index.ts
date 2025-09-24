import { config as dotenvConfig } from "dotenv";
import {
    createPublicClient,
    defineChain,
    http,
    PublicClient,
} from "viem";
import { config } from "./config";
import { DVNVerifier } from "./Verifier";
import {createClient, RedisClientType} from "redis";

dotenvConfig();

const chain = defineChain({
    id: config.networkA.chainId,
    name: config.networkA.name,
    nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
    rpcUrls: {
        default: {
            http: [config.networkA.rpc],
        },
    },
});

const publicClient: PublicClient = createPublicClient({
    chain,
    transport: http(config.networkA.rpc),
});

const redisClient: RedisClientType<any, any> = createClient({
    url: process.env.REDIS_URL!,
});

async function startVerifier() {
    await redisClient.connect();

    const dvnVerifier = new DVNVerifier(publicClient, redisClient);
    // Start the DVN verifier service
    dvnVerifier.start();
}

startVerifier().catch((error) => {
    console.error("Error starting verifier:", error);
    process.exit(1);
});