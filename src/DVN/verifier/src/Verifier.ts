import { WalletClient, PublicClient, HttpTransport, Chain, Account } from "viem";
import { RedisClientType } from "redis";
import { chainConfig } from "./config";
import { keccak256 } from "viem";

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

        const packetEvent = verification.packetEvent;
        const { packetHeader, payloadHash } = packetEvent;
        if (!packetHeader || !payloadHash) {
            console.log("Missing packetHeader or payloadHash in PacketSent event");
            return;
        }

        // Compute headerHash from packetHeader using keccak256
        const headerHash = keccak256(packetHeader);

        // Use required confirmations from the verification event, defaulting to 1 if not provided
        const requiredConfirmation = verification.confirmations || 1;

        // Call _verified on the receive library contract
        let verified: boolean = await this.publicClient.readContract({
            address: verification.libraryAddress as `0x${string}`,
            abi: [
                {
                    inputs: [
                        { internalType: "address", name: "_dvn", type: "address" },
                        { internalType: "bytes32", name: "_headerHash", type: "bytes32" },
                        { internalType: "bytes32", name: "_payloadHash", type: "bytes32" },
                        { internalType: "uint256", name: "_requiredConfirmation", type: "uint256" }
                    ],
                    name: "_verified",
                    outputs: [{ internalType: "bool", name: "", type: "bool" }],
                    stateMutability: "view",
                    type: "function"
                }
            ],
            functionName: "_verified",
            args: [chainConfig.dvn, headerHash, payloadHash, requiredConfirmation]
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
                args: [packetHeader, payloadHash, requiredConfirmation]
            });
            console.log("verifyPacket transaction sent:", txResult);

            // Call _verified again after calling verifyPacket
            verified = await this.publicClient.readContract({
                address: verification.libraryAddress as `0x${string}`,
                abi: [
                    {
                        inputs: [
                            { internalType: "address", name: "_dvn", type: "address" },
                            { internalType: "bytes32", name: "_headerHash", type: "bytes32" },
                            { internalType: "bytes32", name: "_payloadHash", type: "bytes32" },
                            { internalType: "uint256", name: "_requiredConfirmation", type: "uint256" }
                        ],
                        name: "_verified",
                        outputs: [{ internalType: "bool", name: "", type: "bool" }],
                        stateMutability: "view",
                        type: "function"
                    }
                ],
                functionName: "_verified",
                args: [chainConfig.dvn, headerHash, payloadHash, requiredConfirmation]
            });
            console.log(`_verified after verifyPacket returned: ${verified}`);
            if (!verified) {
                console.log("Verification still failed after calling verifyPacket. Aborting.");
                return;
            }
        }
    }
}