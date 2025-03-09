import {RedisClientType} from "redis";
import {abi as endpointABI} from "../abis/EndpointV2";
import { PublicClient, keccak256 } from "viem";
import {destinationConfig} from "../config";

export class PacketVerifiedHandler {

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
            this.client.watchContractEvent({
                address: destinationConfig.endpoint,
                abi: endpointABI,
                eventName: "PacketVerified",
                onLogs: async (logs) => {
                    // Define constants for payload hash values
                    const EMPTY_PAYLOAD_HASH = '0x0000000000000000000000000000000000000000000000000000000000000000';
                    // Compute NIL_PAYLOAD_HASH as keccak256 hash of 'NIL_PAYLOAD'.
                    const NIL_PAYLOAD_HASH = keccak256(new TextEncoder().encode('NIL_PAYLOAD'));

                    const { nonce, sender } = packetData.packet;

                    // Read the payload hash from the endpoint contract
                    const payloadHash: string = await this.client.readContract({
                      address: destinationConfig.endpoint,
                      abi: endpointABI,
                      functionName: 'inboundPayloadHash',
                      args: [receiver, dstEid, sender, nonce]
                    });

                    let isExecutable = false;

                    // Check if packet is executed (payload cleared and nonce within lazyInboundNonce)
                    if (payloadHash === EMPTY_PAYLOAD_HASH) {
                      const lazyInboundNonce: any = await this.client.readContract({
                        address: destinationConfig.endpoint,
                        abi: endpointABI,
                        functionName: 'lazyInboundNonce',
                        args: [receiver, dstEid, sender]
                      });
                      if (nonce <= Number(lazyInboundNonce)) {
                        isExecutable = true;
                      }
                    }

                    // Check if packet is executable (payload not nil and nonce within inboundNonce) if not already executable
                    if (!isExecutable && payloadHash !== NIL_PAYLOAD_HASH) {
                      const inboundNonce: any = await this.client.readContract({
                        address: destinationConfig.endpoint,
                        abi: endpointABI,
                        functionName: 'inboundNonce',
                        args: [receiver, dstEid, sender]
                      });
                      if (nonce <= Number(inboundNonce)) {
                        isExecutable = true;
                      }
                    }

                    if (isExecutable) {
                        const executionMessage = {
                            packetData,
                            receiver,
                            dstEid,
                            status: "executable",
                            timestamp: new Date().toISOString()
                        };
                        await this.redisClient.publish("execution", JSON.stringify(executionMessage));
                    }
                },
            });
        } catch (error) {
            console.error("Error handling packet event:", error);
        }
    }
}