import {Account, HttpTransport, WalletClient} from 'viem';
import {Chain} from 'viem/chains';
import {config as dotenvConfig} from 'dotenv';
import {abi as receiveLibABI} from './abis/ReceiveUln302';
import {RedisClientType} from "redis";

dotenvConfig();

export class LayerZeroCommitter {
    constructor(
        private walletClient: WalletClient<HttpTransport, Chain, Account>,
        private redisSubscribeClient: RedisClientType<any, any>,
        private redisPublishClient: RedisClientType<any, any>,
    ) {}

   async start() {
        console.log('Starting Redis subscription for verification events...');
        // Subscribe to the 'verification' channel
        const subscription = this.redisSubscribeClient.subscribe('verification', async (message: string) => {
            console.log('Verification event received:', message);
            try {
                const verification: any = JSON.parse(message);
                await this.processVerification(verification);
            } catch (error) {
                console.error('Error processing verification event:', error);
            }
        });
    }

    private async processVerification(verification: any): Promise<void> {
        console.log('Processing verification:', verification);

        // Construct a unique cache key based on the packet header
        const cacheKey = `verification:${verification.packetData.packetHeader}`;

        // Check if this verification was already submitted
        const alreadySubmitted = await this.redisPublishClient.get(cacheKey);
        if (alreadySubmitted) {
            console.log('Verification already submitted. Skipping processing for:', cacheKey);
            return;
        }

        // Store the verification in Redis with a TTL of 5 minutes
        await this.redisPublishClient.set(cacheKey, 'submitted', { EX: 300 });

        const txResult = await this.walletClient.writeContract({
            address: verification.libraryAddress as `0x${string}`,
            abi: receiveLibABI,
            functionName: "commitVerification",
            args: [verification.packetData.packetHeader, verification.packetData.payloadHash],
        });

        console.log("Commit verification submitted:", txResult);
    }
}