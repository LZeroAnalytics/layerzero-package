import {decodeAbiParameters, PublicClient} from "viem";
import { RedisClientType } from "redis";
import { sourceConfig } from "../config";
import { LZMessageEvent } from "../types";
import { abi as endpointABI } from "../abis/EndpointV2";
import { PacketV1Codec } from "@layerzerolabs/lz-v2-utilities";
import { keccak256, concat } from "viem";

export class PacketSentWatcher {
    constructor(
        private client: PublicClient,
        private redisClient: RedisClientType<any, any>
    ) {
    }

    start() {
        console.log("Starting PacketSentWatcher...");

        // Use watchContractEvent to subscribe to PacketSent events
        this.client.watchContractEvent({
            address: sourceConfig.endpoint,
            abi: endpointABI,
            eventName: "PacketSent",
            onLogs: async (logs) => {
                for (const log of logs) {
                    console.log("PacketSent event detected, tx:", log.transactionHash);
                    const event = await this.processLog(log);
                    if (event) {
                        const dvnResult = await this.queryDVNFeePaid(event);
                        if (dvnResult.shouldProcess) {
                            // Pass all DVN addresses to the verifier - let verifier decide which to use
                            const enhancedEvent = {
                                ...event,
                                allDVNs: dvnResult.allDVNs,  // All DVN addresses from the event
                                requiredDVNs: dvnResult.requiredDVNs,  // Required DVNs from OApp
                                optionalDVNs: dvnResult.optionalDVNs   // Optional DVNs from OApp
                            };
                            
                            await this.redisClient.publish('packetEvents', JSON.stringify(enhancedEvent));
                            console.log(`Published PacketSent event to Redis on 'packetEvents' channel with ${dvnResult.allDVNs.length} DVN addresses.`);
                        } else {
                            console.log(`No DVN fee paid for tx: ${event.transactionHash}`);
                        }
                    }
                }
            }
        });
    }

    private async processLog(log: any): Promise<LZMessageEvent | undefined> {
        console.log(`Log received for tx: ${log.transactionHash}`);
        if (!log.transactionHash || !log.logIndex) return;
        if (log.topics.length === 0 || log.topics[0] === undefined) return;

        const payLoad = log.args.encodedPayload as `0x${string}`;
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
        const receipt = await this.client.getTransactionReceipt({hash: event.transactionHash as `0x${string}`});
        if (!receipt) {
            console.log(`[queryDVNFeePaid] Failed to retrieve transaction receipt for tx: ${event.transactionHash}`);
            return { shouldProcess: false, allDVNs: [], requiredDVNs: [], optionalDVNs: [] };
        }
        
        // Compute the DVNFeePaid event signature
        const dvnFeePaidEventSignature = keccak256(new TextEncoder().encode("DVNFeePaid(address[],address[],uint256[])"));
        const feePaidEvent = receipt.logs.find((log: any) => log.topics[0] === dvnFeePaidEventSignature);
        
        if (feePaidEvent) {
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
        }
        
        return { shouldProcess: false, allDVNs: [], requiredDVNs: [], optionalDVNs: [] };
    }
}