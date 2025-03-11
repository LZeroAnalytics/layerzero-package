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
                        const dvnPaid = await this.queryDVNFeePaid(event);
                        if (dvnPaid) {
                            await this.redisClient.publish('packetEvents', JSON.stringify(event));
                            console.log(`Published PacketSent event to Redis on 'packetEvents' channel as DVN fee is paid.`);
                        } else {
                            console.log(`No matching DVNFeePaid event found for tx: ${event.transactionHash}`);
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

    private async queryDVNFeePaid(event: LZMessageEvent): Promise<boolean> {
        const receipt = await this.client.getTransactionReceipt({hash: event.transactionHash as `0x${string}`});
        if (!receipt) {
            console.log(`[queryDVNFeePaid] Failed to retrieve transaction receipt for tx: ${event.transactionHash}`);
            return false;
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
            const dvnAddress = sourceConfig.dvn.toLowerCase();
            if (requiredDVNs.map(addr => addr.toLowerCase()).includes(dvnAddress) ||
                optionalDVNs.map(addr => addr.toLowerCase()).includes(dvnAddress)) {
                return true;
            } else {
                console.log(`[queryDVNFeePaid] DVN address ${sourceConfig.dvn} not found in event parameters.`);
                return false;
            }
        }
        return false;
    }
}