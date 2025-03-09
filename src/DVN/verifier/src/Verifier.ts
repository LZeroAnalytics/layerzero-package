import { WalletClient, PublicClient, HttpTransport, Chain, Account } from "viem";
import { RedisClientType } from "redis";
import { chainConfig } from "./config";
import { keccak256 } from "viem";
import { abi as receiveUlnABI } from "./abis/ReceiveUln302";

export class Verifier {
    constructor(
        private walletClient: WalletClient<HttpTransport, Chain, Account>,
        private publicClient: PublicClient<any, any>,
        private redisClient: RedisClientType<any, any>
    ) {}

    async start() {
        console.log("Verifier starting...");
        // Subscribe to the "verification" channel
        this.redisClient.subscribe("verification", async (message: string) => {
            console.log("Verification event received:", message);
            try {
                const verification = JSON.parse(message);
                await this.processVerification(verification);
            } catch (error) {
                console.error("Error processing verification event:", error);
            }
        });
    }

    private async processVerification(verification: any): Promise<void> {
        // Check if the receive lib from the event equals the trusted one from config
        if (
            verification.libraryAddress.toLowerCase() !==
            chainConfig.trustedReceiveLib.toLowerCase()
        ) {
            console.log(
                `Receive lib mismatch: expected ${chainConfig.trustedReceiveLib}, got ${verification.libraryAddress}`
            );
            return;
        }

        const { packetEvent, libraryAddress, ulnConfig } = verification;
        if (!packetEvent || !packetEvent.packetHeader || !packetEvent.payloadHash) {
            console.log("Missing packetHeader or payloadHash in PacketSent event");
            return;
        }

        // Compute headerHash from packetHeader using keccak256
        const headerHash = keccak256(packetEvent.packetHeader);

        let verified: boolean = await this.publicClient.readContract({
            address: libraryAddress as `0x${string}`,
            abi: receiveUlnABI,
            functionName: "verifiable",
            args: [ulnConfig, headerHash, packetEvent.payloadHash]
        });
        console.log(`_verified returned: ${verified}`);

        if (!verified) {
            console.log("Verification failed. Calling verifyPacket on DVN contract...");
            // Call verifyPacket on the DVN contract
            const txResult = await this.walletClient.writeContract({
                address: chainConfig.dvn as `0x${string}`,
                abi: [
                    {
                        inputs: [
                            { internalType: "bytes", name: "_packetHeader", type: "bytes" },
                            { internalType: "bytes32", name: "_payloadHash", type: "bytes32" },
                            { internalType: "uint64", name: "_confirmations", type: "uint64" }
                        ],
                        name: "verifyPacket",
                        outputs: [],
                        stateMutability: "nonpayable",
                        type: "function"
                    }
                ],
                functionName: "verifyPacket",
                args: [packetEvent.packetHeader, packetEvent.payloadHash, ulnConfig.confirmations]
            });
            console.log("verifyPacket transaction sent:", txResult);

            // Call _verified again after calling verifyPacket
            verified = await this.publicClient.readContract({
                address: libraryAddress as `0x${string}`,
                abi: receiveUlnABI,
                functionName: "verifiable",
                args: [ulnConfig, headerHash, packetEvent.payloadHash]
            });
            console.log(`_verified after verifyPacket returned: ${verified}`);
            if (!verified) {
                console.log("Verification still failed after calling verifyPacket. Aborting.");
                return;
            }
        }
    }
}