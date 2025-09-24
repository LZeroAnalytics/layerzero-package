import {decodeAbiParameters, PublicClient} from "viem";
import { RedisClientType } from "redis";
import {config} from "../config";
import { LZMessageEvent } from "../types";
import { abi as endpointABI } from "../abis/EndpointV2";
import { PacketV1Codec } from "@layerzerolabs/lz-v2-utilities";
import { keccak256 } from "viem";

export class PacketSentWatcher {
    constructor(
        private client: PublicClient,
        private redisClient: RedisClientType<any, any>,
        private endpointAddress: `0x${string}`,
        private executorAddress: `0x${string}`
    ) {}

    start() {
        console.log("Starting PacketSentWatcher...");
        console.log(`[EXECUTOR-WATCHER] Starting to watch endpoint: ${this.endpointAddress}`);

        // Use watchContractEvent to subscribe to PacketSent events
        this.client.watchContractEvent({
            address: this.endpointAddress,
            abi: endpointABI,
            eventName: "PacketSent",
            onLogs: async (logs) => {
                for (const log of logs) {
                    console.log("PacketSent event detected, tx:", log.transactionHash);
                    const event = await this.processLog(log);
                    if (event) {
                        const feePaid = await this.queryFeePaid(event);
                        
                        // TEMPORARY: Always process events for debugging
                        console.log(`[DEBUG] Processing event regardless of executor fee validation for tx: ${event.transactionHash}`);
                        try {
                            await this.redisClient.publish('packetEvents', JSON.stringify(event));
                            console.log(`[DEBUG] Published PacketSent event to Redis regardless of executor fee status`);
                        } catch (redisError: any) {
                            console.log(`[ERROR] Failed to publish to Redis: ${redisError.message}`);
                        }
                        
                        if (feePaid !== null) {
                            console.log(`Executor fee validation passed for tx: ${event.transactionHash}, feePaid: ${feePaid}`);
                        } else {
                            console.log(`Executor fee validation failed for tx: ${event.transactionHash}, but processing anyway for debug`);
                        }
                    }
                }
            },
            onError: (error) => {
                console.log(`[ERROR] Executor PacketSentWatcher error: ${error.message}`);
            }
        });
    }

    private async processLog(log: any): Promise<LZMessageEvent | undefined> {
        console.log(`Log received for tx: ${log.transactionHash}`);
        if (!log.transactionHash || !log.logIndex) return;
        if (log.topics.length === 0 || log.topics[0] === undefined) return;

        const payLoad = log.args.encodedPacket as `0x${string}`;
        if (!payLoad) return;

        const packetV1Codec = PacketV1Codec.from(payLoad);
        const packet = packetV1Codec.toPacket();
        const packetHeader = packetV1Codec.header() as `0x${string}`;
        const payloadHash = packetV1Codec.payloadHash() as `0x${string}`;

        console.log(`Log valid for tx: ${log.transactionHash}!`);
        return {
            packet,
            packetHeader,
            payloadHash,
            rawPayload: payLoad,
            transactionHash: log.transactionHash,
        };
    }

    private async queryFeePaid(event: LZMessageEvent): Promise<bigint | null> {
        console.log(`[queryFeePaid] Checking executor fee for tx: ${event.transactionHash}`);
        const receipt = await this.client.getTransactionReceipt({
            hash: event.transactionHash as `0x${string}`,
        });
        if (!receipt) {
            console.log(`[queryFeePaid] Failed to retrieve transaction receipt for tx: ${event.transactionHash}`);
            return null;
        }
        
        console.log(`[queryFeePaid] Transaction receipt found with ${receipt.logs.length} logs`);
        const executorFeePaidEventSignature = keccak256(new TextEncoder().encode("ExecutorFeePaid(address,uint256)"));
        console.log(`[queryFeePaid] Looking for ExecutorFeePaid event signature: ${executorFeePaidEventSignature}`);
        
        // Log all event signatures in the receipt for debugging
        receipt.logs.forEach((log: any, index: number) => {
            console.log(`[queryFeePaid] Log ${index}: signature ${log.topics[0]}, address ${log.address}`);
        });
        
        const feePaidEvent = receipt.logs.find((log: any) =>
            log.topics[0] === executorFeePaidEventSignature);
        if (feePaidEvent) {
            const decodedData = decodeAbiParameters([{ type: "address" }, { type: "uint256" }], feePaidEvent.data);
            console.log("Decoded data from PacketSent", decodedData);
            const executorAddress = (decodedData[0] as string).toLowerCase();
            if (executorAddress === this.executorAddress.toLowerCase()) {
                return decodedData[1] as bigint;
            } else {
                console.log(`[queryFeePaid] Executor address mismatch: expected ${this.executorAddress}, got ${executorAddress}`);
                return null;
            }
        } else {
            console.log(`[queryFeePaid] No ExecutorFeePaid event found in transaction ${event.transactionHash}`);
        }
        return null;
    }
}