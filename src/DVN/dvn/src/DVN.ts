import {
    Account,
    Chain,
    createWalletClient,
    HttpTransport,
    getContract,
    defineChain, WalletClient,
} from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { chainConfig } from "./config";
import { LZMessageEvent } from "./types";
import { bytes32ToEthAddress, hexZeroPadTo32 } from "@layerzerolabs/lz-v2-utilities";

// Import ABIs for the Endpoint, ReceiveUln302 view and non-view contracts.
import { abi as endpointABI } from "./abis/EndpointV2";
import { abi as receiveLibViewABI } from "./abis/ReceiveUln302View";
import { abi as receiveLibABI } from "./abis/ReceiveUln302";
import { abi as dvnABI } from "./abis/DVNContract";

// The DVN offchain component implements the DVN workflow.
export class DVN {
    client: ReturnType<typeof createWalletClient>;
    // We assume chainConfig contains fields: endpoint, trustedReceiveLib, trustedReceiveLibView, etc.
    config = chainConfig;

    constructor(client: WalletClient<HttpTransport, Chain, Account>) {
        this.client = client;
    }

    // Process an event received from Redis.
    async processEvent(event: LZMessageEvent): Promise<void> {
        console.log(`DVN processing event ${event.transactionHash}`);

        // The OApp address is derived from the packet receiver (convert bytes32 to 20-byte address).
        const oapp = bytes32ToEthAddress(event.packet.receiver) as `0x${string}`;

        // Query the Endpoint for the receive library for this OApp and srcEid.
        const endpoint = getContract({
            address: this.config.endpoint,
            abi: endpointABI,
            client: this.client,
        });

        const receiveLibResult = await endpoint.read.getReceiveLibrary([
            oapp,
            event.packet.srcEid,
        ]);
        const receiveLibAddress = receiveLibResult[0] as `0x${string}`;
        console.log(`Received library for OApp ${oapp} (srcEid ${event.packet.srcEid}): ${receiveLibAddress}`);

        // Query the receive library view contract to get the ULN configuration.
        const receiveLibContract = getContract({
            address: this.config.trustedReceiveLib,
            abi: receiveLibABI,
            client: this.client,
        });

        const dvnContract = getContract({
            address: this.config.dvn,
            abi: dvnABI,
            client: this.client,
        });

        const ulnConfig = await receiveLibContract.read.getUlnConfig([
            oapp,
            event.packet.srcEid,
        ]);
        console.log("Retrieved ULN config:", ulnConfig);

        // Check idempotency via the verifiable function.
        //TODO: Do Idempotency check
        /*const alreadyVerified: boolean = await receiveLibContract.read.verifiable([
            event.packetHeader,
            event.payloadHash,
        ]);
        console.log(`DVN idempotency check: ${alreadyVerified}`);

        if (alreadyVerified) {
            console.log("Packet already verified. DVN workflow complete.");
            return;
        }*/

        // Otherwise, call _verify on the receive library contract.
        const confirmations: bigint = ulnConfig.confirmations;

        console.log("Submitting DVN _verify transaction...");
        const tx = await dvnContract.write.verifyPacket(
            [event.packetHeader, event.payloadHash, confirmations],
            {
                gas: BigInt(1_000_000),
                account: this.client.account!,
                chain: this.client.chain!,
            },
        );
        console.log(`DVN _verify transaction sent: ${tx}`);
    }
}