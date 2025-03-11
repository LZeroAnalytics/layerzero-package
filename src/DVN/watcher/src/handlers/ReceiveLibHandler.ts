import { PublicClient } from "viem";
import { RedisClientType } from "redis";
import { destinationConfig } from "../config";
import { abi as endpointABI } from "../abis/EndpointV2";
import { abi as sendUlnABI } from "../abis/SendUln302";

export class ReceiveLibHandler {
    constructor(
        private client: PublicClient,
        private redisSubscribeClient: RedisClientType<any, any>,
        private redisPublishClient: RedisClientType<any, any>
    ) {}

    async start() {
        console.log("Starting ReceiveLibHandler...");

        // Subscribe to the "packetEvents" Redis channel to receive assignment messages
        this.redisSubscribeClient.subscribe("packetEvents", async (message) => {
            console.log("DVN packet event received:", message);
            const packetData = JSON.parse(message);

            if (!packetData) {
                console.log("No packetData:", message);
                return;
            }

            await this.handleJobAssignmentMessage(packetData);
        });
    }

    private async handleJobAssignmentMessage(packetData: any): Promise<void> {
        // From the PacketSent event, extract the receiver and dstEid
        const { receiver, dstEid } = packetData.packet;
        //TODO: Try checksummed address
        const normalizedReceiver = receiver.length === 66 ? `0x${receiver.slice(-40)}` : receiver;
        if (!receiver || !dstEid) {
            console.log("Missing receiver or dstEid in PacketSent event");
            return;
        }

        // Call getReceiveLibrary on the destination chain endpoint to get the receive library address
        const result = await this.client.readContract({
            address: destinationConfig.endpoint,
            abi: endpointABI,
            functionName: "getReceiveLibrary",
            args: [normalizedReceiver, dstEid]
        });
        // If the result is an array (e.g., [libraryAddress, flag]), extract the first element and cast to string
        const libraryAddress = (Array.isArray(result) ? result[0] : result) as string;
        console.log(`Receive library address obtained: ${libraryAddress}`);

        // Get the full ULN config from the send library
        const ulnConfig = await this.getUlnConfig(libraryAddress, normalizedReceiver, dstEid);
        if (!ulnConfig) {
            console.error("Failed to retrieve ULN config");
            return;
        }
        console.log("ULN Config retrieved:", ulnConfig);
        console.log(`Waiting for ${ulnConfig.confirmations} confirmations...`);

        // Wait for the required confirmations
        await this.waitConfirmations(Number(ulnConfig.confirmations));

        // Publish a verification message to Redis so that it can be matched with the PacketSent event later
        const verificationMessage = {
            packetData,
            libraryAddress,
            ulnConfig,
            status: "confirmed",
            timestamp: new Date().toISOString()
        };
        await this.redisPublishClient.publish("verification", JSON.stringify(verificationMessage)); //TODO: Handle BigInt
    }

    private async getUlnConfig(libraryAddress: string, receiver: string, dstEid: number): Promise<any> {
        try {
            const config = await this.client.readContract({
                address: libraryAddress as `0x${string}`,
                abi: sendUlnABI,
                functionName: "getUlnConfig",
                args: [receiver as `0x${string}`, dstEid]
            });
            return config;
        } catch (error) {
            console.error("Error reading ULN config from send library:", error);
            return null;
        }
    }

    private async waitConfirmations(confirmations: number): Promise<void> {
        // Get the current block number as a starting point
        const startingBlock = await this.client.getBlockNumber();
        console.log("Starting block:", startingBlock);

        return new Promise((resolve) => {
            const interval = setInterval(async () => {
                const currentBlock = await this.client.getBlockNumber();
                console.log(`Current block: ${currentBlock} (waiting until block ${startingBlock + BigInt(confirmations)})`);
                if (currentBlock >= startingBlock + BigInt(confirmations)) {
                    clearInterval(interval);
                    resolve();
                }
            }, 5000);
        });
    }
}