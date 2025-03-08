import { PublicClient } from "viem";
import { RedisClientType } from "redis";
import { destinationConfig } from "../config";
import { abi as endpointABI } from "../abis/EndpointV2";

export class ReceiveLibHandler {
    constructor(
        private client: PublicClient,
        private redisClient: RedisClientType<any, any>
    ) {}

    async start() {
        console.log("Starting ReceiveLibHandler...");

        // Subscribe to the "jobAssignment" Redis channel to receive assignment messages
        this.redisClient.subscribe("jobAssignment", async (message) => {
            console.log("Job assignment message received:", message);
            await this.handleJobAssignmentMessage(message);
        });
    }

    private async handleJobAssignmentMessage(message: string): Promise<void> {
        const composite = JSON.parse(message);
        const { key, packetEvent } = composite;
        // From the PacketSent event, extract the receiver and dstEid
        const { receiver, dstEid } = packetEvent.packet;
        if (!receiver || !dstEid) {
            console.log("Missing receiver or dstEid in PacketSent event");
            return;
        }

        // Call getReceiveLibrary on the destination chain endpoint to get the receive library address
        const result = await this.client.readContract({
            address: destinationConfig.endpoint,
            abi: endpointABI,
            functionName: "getReceiveLibrary",
            args: [receiver, dstEid]
        });
        // If the result is an array (e.g., [libraryAddress, flag]), extract the first element and cast to string
        const libraryAddress = (Array.isArray(result) ? result[0] : result) as string;
        console.log(`Receive library address obtained: ${libraryAddress}`);

        // Get the confirmations required from the receive library configuration
        const confirmations = await this.getConfirmationsRequired(libraryAddress);
        console.log(`Confirmations required: ${confirmations}`);
        console.log(`Waiting for ${confirmations} confirmations...`);

        // Wait for the required confirmations
        await this.waitConfirmations(confirmations);

        // Publish a verification message to Redis so that it can be matched with the PacketSent event later
        const verificationMessage = {
            key,
            libraryAddress,
            receiver,
            dstEid,
            status: "confirmed",
            timestamp: new Date().toISOString()
        };
        await this.redisClient.publish("verification", JSON.stringify(verificationMessage));
        console.log("Verification message published to Redis for key:", key);
    }

    private async getConfirmationsRequired(libraryAddress: string): Promise<number> {
        const abi = [
            {
                constant: true,
                inputs: [],
                name: "confirmationsRequired",
                outputs: [{ name: "", type: "uint256" }],
                stateMutability: "view",
                type: "function"
            }
        ];
        try {
            const confirmations = await this.client.readContract({
                address: libraryAddress as `0x${string}`,
                abi,
                functionName: "confirmationsRequired",
                args: []
            });
            return Number(confirmations);
        } catch (error) {
            console.error("Error reading confirmations required from receive library:", error);
            return 0;
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