import {decodeAbiParameters, PublicClient} from "viem";
import { RedisClientType } from "redis";
import { config } from "../config";
import { LZMessageEvent } from "../types";
import { abi as endpointABI } from "../abis/EndpointV2";
import { PacketV1Codec } from "@layerzerolabs/lz-v2-utilities";
import { keccak256, concat } from "viem";

export class PacketSentWatcher {
    constructor(
        private client: PublicClient,
        private redisClient: RedisClientType<any, any>,
        private endpointAddress: `0x${string}`
    ) {
    }

    start() {
        console.log("Starting PacketSentWatcher...");

        console.log(`[DVN-WATCHER] Starting to watch endpoint: ${this.endpointAddress}`);
        
        // Use watchContractEvent to subscribe to PacketSent events
        this.client.watchContractEvent({
            address: this.endpointAddress,
            abi: endpointABI,
            eventName: "PacketSent",
            onLogs: async (logs) => {
                console.log(`🎉 [DVN-WATCHER] PacketSent event detected! Count: ${logs.length}`);
                logs.forEach((log, i) => {
                    console.log(`  Event ${i+1}: TX ${log.transactionHash}, Block ${log.blockNumber}`);
                });
                
                // Also do the original processing
                for (const log of logs) {
                    console.log("PacketSent event detected, tx:", log.transactionHash);
                    const event = await this.processLog(log);
                    if (event) {
                        const dvnResult = await this.queryDVNFeePaid(event);
                        
                        // TEMPORARY: Always process events for debugging
                        console.log(`[DEBUG] Processing event regardless of DVN fee validation for tx: ${event.transactionHash}`);
                        const enhancedEvent = {
                            ...event,
                            allDVNs: dvnResult.allDVNs,  // All DVN addresses from the event
                            requiredDVNs: dvnResult.requiredDVNs,  // Required DVNs from OApp
                            optionalDVNs: dvnResult.optionalDVNs   // Optional DVNs from OApp
                        };
                        
                        try {
                            await this.redisClient.publish('packetEvents', JSON.stringify(enhancedEvent));
                            console.log(`[DEBUG] Published PacketSent event to Redis regardless of DVN fee status`);
                        } catch (redisError: any) {
                            console.log(`[ERROR] Failed to publish to Redis: ${redisError.message}`);
                        }
                        
                        if (dvnResult.shouldProcess) {
                            console.log(`DVN fee validation passed for tx: ${event.transactionHash}`);
                        } else {
                            console.log(`DVN fee validation failed for tx: ${event.transactionHash}, but processing anyway for debug`);
                        }
                    }
                }
            },
            onError: (error) => {
                console.log(`[ERROR] DVN PacketSentWatcher error: ${error.message}`);
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

    private async queryDVNFeePaid(event: LZMessageEvent): Promise<{shouldProcess: boolean, allDVNs: string[], requiredDVNs: string[], optionalDVNs: string[]}> {
        console.log(`[queryDVNFeePaid] Checking DVN fee for tx: ${event.transactionHash}`);
        const receipt = await this.client.getTransactionReceipt({hash: event.transactionHash as `0x${string}`});
        if (!receipt) {
            console.log(`[queryDVNFeePaid] Failed to retrieve transaction receipt for tx: ${event.transactionHash}`);
            return { shouldProcess: false, allDVNs: [], requiredDVNs: [], optionalDVNs: [] };
        }
        
        console.log(`[queryDVNFeePaid] Transaction receipt found with ${receipt.logs.length} logs`);
        
        // Compute the DVNFeePaid event signature
        const dvnFeePaidEventSignature = keccak256(new TextEncoder().encode("DVNFeePaid(address[],address[],uint256[])"));
        console.log(`[queryDVNFeePaid] Looking for DVNFeePaid event signature: ${dvnFeePaidEventSignature}`);
        
        // Log all event signatures in the receipt for debugging
        receipt.logs.forEach((log: any, index: number) => {
            console.log(`[queryDVNFeePaid] Log ${index}: signature ${log.topics[0]}, address ${log.address}`);
        });
        
        const feePaidEvent = receipt.logs.find((log: any) => log.topics[0] === dvnFeePaidEventSignature);
        
        if (feePaidEvent) {
            console.log(`[queryDVNFeePaid] Found DVNFeePaid event!`);
            // Decode the event data using decodeAbiParameters
            const decodedData = decodeAbiParameters([
                {type: "address[]"},
                {type: "address[]"},
                {type: "uint256[]"}
            ], feePaidEvent.data);
            const requiredDVNs = decodedData[0] as string[];
            const optionalDVNs = decodedData[1] as string[];
            
            // Get all DVN addresses from the event
            const allDVNs = [...requiredDVNs, ...optionalDVNs].map(addr => addr.toLowerCase());
            
            console.log(`[queryDVNFeePaid] Found DVN fee paid event with ${allDVNs.length} DVN addresses:`, allDVNs);
            console.log(`[queryDVNFeePaid] Required DVNs:`, requiredDVNs);
            console.log(`[queryDVNFeePaid] Optional DVNs:`, optionalDVNs);
            
            return { 
                shouldProcess: true, 
                allDVNs,
                requiredDVNs: requiredDVNs.map(addr => addr.toLowerCase()),
                optionalDVNs: optionalDVNs.map(addr => addr.toLowerCase())
            };
        } else {
            console.log(`[queryDVNFeePaid] No DVNFeePaid event found in transaction ${event.transactionHash}`);
        }
        
        return { shouldProcess: false, allDVNs: [], requiredDVNs: [], optionalDVNs: [] };
    }
}