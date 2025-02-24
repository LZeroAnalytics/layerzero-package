import {
    Account,
    getContract,
    WalletClient,
    HttpTransport,
    GetContractReturnType,
    Chain,
    padHex,
} from "viem";
import { abi as endpointABI } from "./abis/EndpointV2";
import { abi as receiveLibABI } from "./abis/ReceiveUln302";
import { ChainConfig } from "./config";
import {LZMessageEvent, LZRawEvent, LZVerifiedEvent} from "./types";
import { bytes32ToEthAddress, hexZeroPadTo32 } from "@layerzerolabs/lz-v2-utilities";

const DEFAULT_GAS_LIMIT = 1_000_000;

export class LayerZeroExecutor {
    active: boolean = false;
    // Store raw events keyed by packetHeader.
    rawEvents: { [header: string]: LZRawEvent } = {};
    // Store verified events keyed by header (which should equal the raw event's packetHeader).
    verifiedEvents: { [header: string]: LZVerifiedEvent } = {};

    endpointContract: GetContractReturnType<
        typeof endpointABI,
        WalletClient<HttpTransport, Chain>,
        `0x${string}`
    >;
    receiveLibContract: GetContractReturnType<
        typeof receiveLibABI,
        WalletClient<HttpTransport, Chain>,
        `0x${string}`
    >;

    constructor(public config: ChainConfig, public client: WalletClient<HttpTransport, Chain, Account>) {
        this.endpointContract = getContract({
            address: config.endpoint,
            abi: endpointABI,
            client,
        });
        this.receiveLibContract = getContract({
            address: config.trustedReceiveLib,
            abi: receiveLibABI,
            client,
        });
    }

    addRawEvent(event: LZRawEvent) {
        console.log(`Adding raw event ${event.transactionHash} with header ${event.packetHeader}`);
        this.rawEvents[event.packetHeader] = event;
        // Check if there's a matching verified event.
        if (this.verifiedEvents[event.packetHeader]) {
            this.processCombinedEvent(event.packetHeader);
        }
    }

    addVerifiedEvent(event: LZVerifiedEvent) {
        console.log(`Adding verified event ${event.transactionHash} with header ${event.header}`);
        this.verifiedEvents[event.header] = event;
        // Check if a raw event exists for this header.
        if (this.rawEvents[event.header]) {
            this.processCombinedEvent(event.header);
        }
    }

    async processCombinedEvent(header: string) {
        console.log(`Processing combined event for header ${header}`);
        const rawEvent = this.rawEvents[header];
        const verifiedEvent = this.verifiedEvents[header];
        if (!rawEvent || !verifiedEvent) {
            console.error("Missing raw or verified event for header", header);
            return;
        }
        // Use the raw event's packetHeader and use the verified event's payloadHash.
        await this.commitEvent(rawEvent);
        await this.executeEvent(rawEvent);
        // Remove the processed events from storage.
        delete this.rawEvents[header];
        delete this.verifiedEvents[header];
    }

    async commitEvent(rawEvent: LZRawEvent) {
        console.log(`Committing event ${rawEvent.transactionHash}`);
        const res = await this.receiveLibContract.write.commitVerification(
            [rawEvent.packetHeader, rawEvent.payloadHash],
            {
                gas: BigInt(DEFAULT_GAS_LIMIT),
                account: this.client.account!,
            }
        );
        console.log(`Committed event: ${res}`);
    }

    async executeEvent(rawEvent: LZRawEvent) {
        console.log(`Executing event ${rawEvent.transactionHash}`);
        // Decode the packet from the rawPayload.
        const packet = rawEvent.packet;
        const origin = {
            srcEid: Number(packet.srcEid),
            sender: padHex(packet.sender),
            nonce: BigInt(packet.nonce),
        };
        const receiver = bytes32ToEthAddress(packet.receiver) as `0x${string}`;
        const guid = hexZeroPadTo32(packet.guid) as `0x${string}`;
        const message = packet.message;
        const extraData = "0x";

        const tx = await this.endpointContract.write.lzReceive(
            [origin, receiver, guid, message, extraData],
            {
                gas: BigInt(DEFAULT_GAS_LIMIT),
                account: this.client.account!,
            }
        );
        console.log(`Executed event: ${tx}`);
    }

    start(): () => void {
        if (this.active) throw new Error("Executor already active");
        this.active = true;
        this.startAsync().then(() => {
            console.log("Executor processing loop finished.");
        });
        return () => { this.active = false; };
    }

    async startAsync() {
        while (this.active) {
            // Optionally, you could poll here to process any combined events
            await new Promise((resolve) => setTimeout(resolve, 5000));
        }
        console.log("Executor stopped.");
    }
}