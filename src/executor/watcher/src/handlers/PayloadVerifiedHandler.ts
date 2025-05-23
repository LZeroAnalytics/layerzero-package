import {RedisClientType} from "redis";
import {abi as endpointABI} from "../abis/EndpointV2";
import {abi as receiveLibABI} from "../abis/ReceiveUln302";
import {keccak256, PublicClient, getAddress} from "viem";
import {destinationConfig} from "../config";
import {abi as sendUlnABI} from "../abis/SendUln302";

export class PayloadVerifiedHandler {

    constructor(
        private client: PublicClient,
        private redisSubscribeClient: RedisClientType<any, any>,
        private redisPublishClient: RedisClientType<any, any>
    ) {}

    public async start(): Promise<void> {
        this.redisSubscribeClient.subscribe("packetEvents", async (message: string) => {
            console.log("Payload verified handler received:", message);

            const packetData = JSON.parse(message);

            if (!packetData) {
                console.log(`No packet found in event`);
                return;
            }

            await this.handlePacketEvent(packetData);
        });
    }

    private async handlePacketEvent(packetData: any): Promise<void> {
        const { receiver, srcEid } = packetData.packet;
        const normalizedReceiver = getAddress(receiver.length === 66 ? `0x${receiver.slice(-40)}` : receiver);
        try {
            // Retrieve the receive library from the endpoint contract.
            const result = await this.client.readContract({
                address: destinationConfig.endpoint,
                abi: endpointABI,
                functionName: "getReceiveLibrary",
            args: [normalizedReceiver, srcEid],
            });
            // If result is an array, take the first element.
            const libraryAddress = (Array.isArray(result) ? result[0] : result) as string;
            console.log("Received library address:", libraryAddress);

            const ulnConfig = await this.getUlnConfig(libraryAddress, normalizedReceiver, srcEid);
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
                    console.log("Received Payload verified event:", logs);
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
                            status: "confirmed",
                            timestamp: new Date().toISOString()
                        };
                        console.log("Pushing verifiable message:", verificationMessage);
                        await this.redisPublishClient.publish("verification", JSON.stringify(verificationMessage));
                    }
                },
            });
        } catch (error) {
            console.error("Error handling packet event:", error);
        }
    }

    private async getUlnConfig(libraryAddress: string, receiver: string, srcEid: number): Promise<any> {
        try {
            return await this.client.readContract({
                address: libraryAddress as `0x${string}`,
                abi: sendUlnABI,
                functionName: "getUlnConfig",
                args: [receiver as `0x${string}`, srcEid]
            });
        } catch (error) {
            console.error("Error reading ULN config from send library:", error);
            return null;
        }
    }
}