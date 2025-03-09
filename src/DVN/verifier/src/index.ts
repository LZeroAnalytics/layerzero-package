import { config as dotenvConfig } from "dotenv";
import {
    createWalletClient,
    createPublicClient,
    defineChain,
    http,
    WalletClient,
    PublicClient,
    Chain,
    Account,
    HttpTransport,
} from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { chainConfig } from "./config";
import { Verifier } from "./Verifier";
import {createClient, RedisClientType} from "redis";

dotenvConfig();

const dvnPrivateKey = chainConfig.privateKey as `0x${string}`;
const account = privateKeyToAccount(dvnPrivateKey);

const chain = defineChain({
    id: chainConfig.chainId,
    name: chainConfig.name,
    nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
    rpcUrls: {
        default: {
            http: [chainConfig.rpc],
        },
    },
});

const walletClient: WalletClient<HttpTransport, Chain, Account> = createWalletClient({
    chain,
    transport: http(chainConfig.rpc),
    account,
});

const publicClient: PublicClient = createPublicClient({
    chain,
    transport: http(chainConfig.rpc),
});

const redisClient: RedisClientType<any, any> = createClient({
    url: process.env.REDIS_URL!,
});

async function startVerifier() {
    await redisClient.connect();

    const verifier = new Verifier(walletClient, publicClient, redisClient);
    // Start the verifier service
    verifier.start();
}

startVerifier().catch((error) => {
    console.error("Error starting verifier:", error);
    process.exit(1);
});