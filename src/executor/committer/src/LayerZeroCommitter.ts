// src/LayerZeroCommitter.ts
import {decodeAbiParameters, HttpTransport, PublicClient} from "viem";
import { Chain } from "viem/chains";
import { chainConfig } from "./config";
import {abi as endpointABI} from "./abis/EndpointV2";
import {config as dotenvConfig} from "dotenv";
import { Packet, PacketV1Codec } from "@layerzerolabs/lz-v2-utilities";

dotenvConfig();

// Define the shape of an event that our committer will output.
export type LZMessageEvent = {
    // The official Packet type is different; define fields you want to store
    // or just store the entire decoded object.
    packet: Packet,
    packetHeader: string;
    payloadHash: string;
    rawPayload: `0x${string}`;
    transactionHash: string;
};

const EXECUTOR_PAID_SIG: `0x${string}` =
    "0x61ed099e74a97a1d7f8bb0952a88ca8b7b8ebd00c126ea04671f92a81213318a";

// A callback type for handling events.
export type OnEvent = (event: LZMessageEvent) => void;

// Our committer class.
export class LayerZeroCommitter {
    private client: PublicClient<HttpTransport, Chain>;

    constructor(client: PublicClient<HttpTransport, Chain>) {
        console.log("Chain config" , chainConfig);
        this.client = client;
    }

    /**
     * Starts watching for PacketSent events.
     * @param onEvent - Callback invoked when a valid event is detected.
     * @returns A function that can be called to stop watching.
     */
    start(onEvent: OnEvent): () => void {
        const stop = this.client.watchContractEvent({
            address: chainConfig.endpoint,
            abi: endpointABI,
            eventName: "PacketSent",
            onLogs: async (logs) => {
                for (const log of logs) {
                    console.log("PacketSent event detected, tx:", log.transactionHash);
                    const event = await this.processLog(log);
                    if (event) {
                        onEvent(event);
                    }
                }
            }
        });
        return stop;
    }

    /**
     * Processes a log entry and returns an LZMessageEvent.
     * (This is a simplified version that just echoes some log data.)
     */
    async processLog(log: any): Promise<LZMessageEvent | undefined> {
        console.log(`Log received for tx: ${log.transactionHash}`);
        if (!log.transactionHash || !log.logIndex) return;
        if (log.topics.length == 0 || log.topics[0] == undefined) return;

        // Fetch the transaction details, which includes an ordered array of all logs in the transaction
        let tx = await this.client.getTransactionReceipt({
            hash: log.transactionHash,
        });

        // Filter on all logs after our actual PacketSent
        let previousLogs = tx.logs
            .filter((txLog) => log.logIndex && txLog.logIndex < log.logIndex)
            .sort((a, b) => b.logIndex - a.logIndex);
        for (let txLog of previousLogs) {
            if (txLog.topics.length == 0) continue; // Ignore LOG0.
            let logSig = txLog.topics[0];
            if (logSig == undefined) continue; // Ignore undefined logs. Unsure whether this is possible or just means out of range, which is already checked.

            // If we reached a new PacketSent, we can stop looking as we did not find an executor payment in time. A new PacketSent would indicate a new message
            // and the next executor getting paid would be for that new event, and not the event we are processing here.
            if (logSig === log.topics[0]) return;

            // If the log is not an executor paid signature, we can continue.
            if (logSig !== EXECUTOR_PAID_SIG) continue;

            if (
                txLog.address.toLowerCase() !== chainConfig.trustedSendLib.toLowerCase()
            )
                continue; // Someone tried to inject a fake event
            // @todo Improvement: use Viem abitypes for this.
            let txLogParams = decodeAbiParameters(
                [
                    { name: "executor", type: "address" },
                    { name: "fee", type: "uint256" },
                ],
                txLog.data,
            );
            let executor = txLogParams[0];

            // If the log is not emitted by our executor, we can continue.
            if (executor.toLowerCase() !== chainConfig.executor.toLowerCase()) {
                console.log(
                    `Executor did not match (${executor.toLowerCase()} != ${chainConfig.executor.toLowerCase()})`,
                );
                continue;
            }

            // As we've found a PacketSent followed by an ExecutorPaid, we can stop looking for more logs and return the decoded log.
            const payLoad = log.args.encodedPayload as `0x${string}`;
            // This should never occur
            if (!payLoad) continue;

            const packetV1Codec = PacketV1Codec.from(payLoad);
            const packet = packetV1Codec.toPacket();
            const packetHeader = packetV1Codec.header();
            const payloadHash = packetV1Codec.payloadHash();

            if (packet.srcEid != chainConfig.eid) continue; // This should not be possible.

            console.log(`Log valid for tx: ${log.transactionHash}!`);
            const event: LZMessageEvent = {
                packet: packet,
                packetHeader: packetHeader,
                payloadHash: payloadHash,
                rawPayload: payLoad,
                transactionHash: log.transactionHash,
            };

            return event;
        }
    }
}