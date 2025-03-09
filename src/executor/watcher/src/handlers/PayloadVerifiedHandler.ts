import {RedisClientType} from "redis";
import {abi as endpointABI} from "../abis/EndpointV2";
import {abi as receiveLibABI} from "../abis/ReceiveUln302";
import {keccak256, PublicClient} from "viem";
import {destinationConfig} from "../config";
import {abi as sendUlnABI} from "../abis/SendUln302";

export class PayloadVerifiedHandler {

    constructor(
        private client: PublicClient,
        private redisClient: RedisClientType<any, any>
    ) {}

    public async start(): Promise<void> {
        this.redisClient.subscribe("jobAssignment", async (message: string) => {
            console.log("Job assignment received:", message);

            const composite = JSON.parse(message);
            const { key } = composite;
            const redisKey = `packet:${key}`;
            const packetData: any = await this.redisClient.get(redisKey);
            if (!packetData) {
                console.log(`No matching PacketSent event found in Redis for key: ${key}`);
                return;
            }
            await this.handlePacketEvent(packetData);
        });
    }

    private async handlePacketEvent(packetData: any): Promise<void> {
        const { receiver, dstEid } = packetData.packet;
        try {
            // Retrieve the receive library from the endpoint contract.
            const result = await this.client.readContract({
                address: destinationConfig.endpoint,
                abi: endpointABI,
                functionName: "getReceiveLibrary",
                args: [receiver, dstEid],
            });
            // If result is an array, take the first element.
            const libraryAddress = (Array.isArray(result) ? result[0] : result) as string;
            console.log("Received library address:", libraryAddress);

            const ulnConfig = await this.getUlnConfig(libraryAddress, receiver, dstEid);
            if (!ulnConfig) {
                console.error("Failed to retrieve ULN config");
                return;
            }
            console.log("ULN Config retrieved:", ulnConfig);

            const headerHash = keccak256(packetData.packetHeader);

            this.client.watchContractEvent({
                address: libraryAddress as `0x${string}`,
                abi: receiveLibABI,
                eventName: "PayloadVerified",
                onLogs: async (logs) => {
                    const isVerifiable = await this.client.readContract({
                        address: libraryAddress as `0x${string}`,
                        abi: receiveLibABI,
                        functionName: "verifiable",
                        args: [ulnConfig, headerHash, packetData.payloadHash],
                    });

                    if (isVerifiable) {
                        const verificationMessage = {
                            packetData,
                            libraryAddress,
                            receiver,
                            dstEid,
                            ulnConfig,
                            status: "confirmed",
                            timestamp: new Date().toISOString()
                        };
                        await this.redisClient.publish("verification", JSON.stringify(verificationMessage));
                    }
                },
            });
        } catch (error) {
            console.error("Error handling packet event:", error);
        }
    }

    private async getUlnConfig(libraryAddress: string, receiver: string, dstEid: number): Promise<any> {
        try {
            return await this.client.readContract({
                address: libraryAddress as `0x${string}`,
                abi: sendUlnABI,
                functionName: "getUlnConfig",
                args: [receiver as `0x${string}`, dstEid]
            });
        } catch (error) {
            console.error("Error reading ULN config from send library:", error);
            return null;
        }
    }
}