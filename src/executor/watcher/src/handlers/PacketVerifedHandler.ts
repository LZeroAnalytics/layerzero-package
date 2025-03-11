import {RedisClientType} from "redis";
import {abi as endpointABI} from "../abis/EndpointV2";
import {PublicClient, keccak256} from "viem";
import {destinationConfig} from "../config";

export class PacketVerifiedHandler {

    constructor(
        private client: PublicClient,
        private redisSubscribeClient: RedisClientType<any, any>,
        private redisPublishClient: RedisClientType<any, any>
    ) {
    }

    public async start(): Promise<void> {
        this.redisSubscribeClient.subscribe("packetEvents", async (message: string) => {
            console.log("Job assignment received:", message);

            const packetData = JSON.parse(message);

            if (!packetData) {
                console.log(`No packet found for ${message}`);
                return;
            }

            await this.handlePacketEvent(packetData);
        });
    }

    private async handlePacketEvent(packetData: any): Promise<void> {
        const {receiver, dstEid, nonce, sender} = packetData.packet
        //TODO: Try checksummed address
        const normalizedReceiver = receiver.length === 66 ? `0x${receiver.slice(-40)}` : receiver;
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


                    // Read the payload hash from the endpoint contract
                    const payloadHash: string = await this.client.readContract({
                        address: destinationConfig.endpoint,
                        abi: endpointABI,
                        functionName: 'inboundPayloadHash',
                    args: [normalizedReceiver, dstEid, sender, nonce]
                    });

                    let isExecutable = false;

                    // Check if packet is executed (payload cleared and nonce within lazyInboundNonce)
                    if (payloadHash === EMPTY_PAYLOAD_HASH) {
                        const lazyInboundNonce: any = await this.client.readContract({
                            address: destinationConfig.endpoint,
                            abi: endpointABI,
                            functionName: 'lazyInboundNonce',
                        args: [normalizedReceiver, dstEid, sender]
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
                        args: [normalizedReceiver, dstEid, sender]
                        });
                        if (nonce <= Number(inboundNonce)) {
                            isExecutable = true;
                        }
                    }

                    if (isExecutable) {
                        const executionMessage = {
                            packetData,
                            receiver: normalizedReceiver,
                            dstEid,
                            status: "executable",
                            timestamp: new Date().toISOString()
                        };
                        await this.redisPublishClient.publish("execution", JSON.stringify(executionMessage));
                    }
                },
            });
        } catch (error) {
            console.error("Error handling packet event:", error);
        }
    }
}