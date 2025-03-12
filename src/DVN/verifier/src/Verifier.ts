import { WalletClient, PublicClient, HttpTransport, Chain, Account } from "viem";
import { RedisClientType } from "redis";
import { chainConfig } from "./config";
import { abi as dvnContractABI } from "./abis/DVNContract";

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
                const verification = JSON.parse(message, (_key, value) => {
                        if (_key === "confirmations" && typeof value === "string") {
                            return BigInt(value);
                        }
                        return value;
                    });
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

        const { packetData, ulnConfig } = verification;
        if (!packetData || !packetData.packetHeader || !packetData.payloadHash) {
            console.log("Missing packetHeader or payloadHash in PacketSent event");
            return;
        }

        // Compute headerHash from packetHeader using keccak256
        let verified: boolean = await this.publicClient.readContract({
            address: chainConfig.dvn as `0x${string}`,
            abi: dvnContractABI,
            functionName: "verified",
            args: [packetData.packetHeader, packetData.payloadHash]
        });
        console.log(`verified returned: ${verified}`);

        if (!verified) {
            console.log("Packet not verified. Calling verifyPac on DVN contract...");
            const txResult = await this.walletClient.writeContract({
                address: chainConfig.dvn as `0x${string}`,
                abi: dvnContractABI,
                functionName: "verifyPacket",
                args: [packetData.packetHeader, packetData.payloadHash, ulnConfig.confirmations]
            });

            console.log("verifyPac transaction sent:", txResult);

            // Wait for the verifyPac transaction to be confirmed
            await this.publicClient.waitForTransactionReceipt({
                hash: txResult,
            });

            verified = await this.publicClient.readContract({
                address: chainConfig.dvn as `0x${string}`,
                abi: dvnContractABI,
                functionName: "verified",
                args: [packetData.packetHeader, packetData.payloadHash]
            });
            console.log(`isPacketVerified after verifyPacket returned: ${verified}`);
            if (!verified) {
                console.log("Packet still not verified after calling verifyPacket. Aborting.");
                return;
            }
        }
    }
}