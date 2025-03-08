import { PublicClient } from "viem";
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
    ) {}

    private computeKey(event: LZMessageEvent): string {
        // Concatenate the packetHeader and payloadHash and compute the keccak256 hash
        return keccak256(concat([event.packetHeader, event.payloadHash]));
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
                        // Compute the key based on packetHeader and payloadHash
                        const key = this.computeKey(event);
                        const redisKey = `packet:${key}`;
                        // Store the processed event in Redis with an expiration of 10 minutes (600 seconds)
                        await this.redisClient.set(redisKey, JSON.stringify(event), { EX: 600 });
                        console.log(`Stored PacketSent event in Redis with key: ${redisKey}`);
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

        // Check whether the send lib is correct by comparing the sender address in the packet
        if (packet.sender.toLowerCase() !== sourceConfig.trustedSendLib.toLowerCase()) {
            console.log(`Send lib mismatch: expected ${sourceConfig.trustedSendLib}, got ${packet.sender}`);
            return;
        }

        console.log(`Log valid for tx: ${log.transactionHash}!`);
        return {
            packet,
            packetHeader,
            payloadHash,
            rawPayload: payLoad,
            transactionHash: log.transactionHash,
        };
    }
}