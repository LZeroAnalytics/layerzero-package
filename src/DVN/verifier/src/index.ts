import { config as dotenvConfig } from "dotenv";
import {
    createPublicClient,
    defineChain,
    http,
    PublicClient,
} from "viem";
import { dvnChainConfig } from "./config";
import { DVNVerifier } from "./Verifier";
import {createClient, RedisClientType} from "redis";

dotenvConfig();

const chain = defineChain({
    id: dvnChainConfig.chainId,
    name: dvnChainConfig.name,
    nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
    rpcUrls: {
        default: {
            http: [dvnChainConfig.rpc],
        },
    },
});

const publicClient: PublicClient = createPublicClient({
    chain,
    transport: http(dvnChainConfig.rpc),
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