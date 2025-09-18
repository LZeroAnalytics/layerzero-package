import { WalletClient, PublicClient, HttpTransport, Chain, Account } from "viem";
import { RedisClientType } from "redis";
import { dvnChainConfig } from "./config";
import { abi as dvnContractABI } from "./abis/DVNContract";
import { privateKeyToAccount } from "viem/accounts";

export interface DVNInstance {
    address: `0x${string}`;
    name: string;
    privateKey: `0x${string}`;
    walletClient: WalletClient<HttpTransport, Chain, Account>;
    publicClient: PublicClient;
}

export class DVNVerifier {
    private dvnInstances: Map<string, DVNInstance> = new Map();
    
    constructor(
        private publicClient: PublicClient,
        private redisClient: RedisClientType<any, any>
    ) {
        this.initializeDVNInstances();
    }
    
    private initializeDVNInstances() {
        for (let i = 0; i < dvnChainConfig.dvnAddresses.length; i++) {
            const address = dvnChainConfig.dvnAddresses[i];
            const name = dvnChainConfig.dvnNames[i];
            const privateKey = dvnChainConfig.privateKeys[i];
            
            if (address && privateKey) {
                const account = privateKeyToAccount(privateKey);
                const walletClient: WalletClient<HttpTransport, Chain, Account> = {
                    chain: this.publicClient.chain,
                    transport: this.publicClient.transport,
                    account,
                } as WalletClient<HttpTransport, Chain, Account>;
                
                const dvnInstance: DVNInstance = {
                    address,
                    name,
                    privateKey,
                    walletClient,
                    publicClient: this.publicClient,
                };
                
                this.dvnInstances.set(address.toLowerCase(), dvnInstance);
                console.log(`Initialized DVN instance: ${name} (${address})`);
            }
        }
    }
    
    async start() {
        console.log("DVN Verifier starting...");
        console.log(`Configured DVNs: ${Array.from(this.dvnInstances.keys()).join(', ')}`);
        
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
            dvnChainConfig.trustedReceiveLib.toLowerCase()
        ) {
            console.log(
                `Receive lib mismatch: expected ${dvnChainConfig.trustedReceiveLib}, got ${verification.libraryAddress}`
            );
            return;
        }
        
        const { packetData, ulnConfig, allDVNs, requiredDVNs, optionalDVNs } = verification;
        if (!packetData || !packetData.packetHeader || !packetData.payloadHash) {
            console.log("Missing packetHeader or payloadHash in PacketSent event");
            return;
        }
        
        // Determine which DVNs to use based on OApp selection
        let dvnsToProcess: DVNInstance[] = [];
        
        if (requiredDVNs && requiredDVNs.length > 0) {
            // OApp specified required DVNs - use only those that we have configured
            dvnsToProcess = requiredDVNs
                .map((addr: string) => this.dvnInstances.get(addr.toLowerCase()))
                .filter(Boolean);
            
            console.log(`OApp specified ${requiredDVNs.length} required DVNs, found ${dvnsToProcess.length} configured DVNs`);
        } else if (allDVNs && allDVNs.length > 0) {
            // OApp specified DVNs but no required/optional distinction - use all that we have configured
            dvnsToProcess = allDVNs
                .map((addr: string) => this.dvnInstances.get(addr.toLowerCase()))
                .filter(Boolean);
            
            console.log(`OApp specified ${allDVNs.length} DVNs, found ${dvnsToProcess.length} configured DVNs`);
        } else {
            // No OApp specification - use default behavior
            if (dvnChainConfig.useAllDVNs) {
                dvnsToProcess = Array.from(this.dvnInstances.values());
                console.log(`Using all ${dvnsToProcess.length} configured DVNs (default behavior)`);
            } else {
                dvnsToProcess = Array.from(this.dvnInstances.values()).slice(0, 1);
                console.log(`Using first DVN only (default behavior)`);
            }
        }
        
        if (dvnsToProcess.length === 0) {
            console.log("No DVN instances available for processing");
            return;
        }
        
        console.log(`Processing verification with ${dvnsToProcess.length} DVN(s):`, 
            dvnsToProcess.map(dvn => dvn.name));
        
        // Process verification with each selected DVN
        const verificationPromises = dvnsToProcess.map(dvn => 
            this.verifyWithDVN(dvn, packetData, ulnConfig)
        );
        
        try {
            await Promise.allSettled(verificationPromises);
        } catch (error) {
            console.error("Error in verification process:", error);
        }
    }
    
    private async verifyWithDVN(
        dvn: DVNInstance, 
        packetData: any, 
        ulnConfig: any
    ): Promise<void> {
        try {
            console.log(`[${dvn.name}] Starting verification process...`);
            
            // Check if packet is already verified
            let verified: boolean = await dvn.publicClient.readContract({
                address: dvn.address,
                abi: dvnContractABI,
                functionName: "verified",
                args: [packetData.packetHeader, packetData.payloadHash]
            });
            
            console.log(`[${dvn.name}] Packet verification status: ${verified}`);
            
            if (!verified) {
                console.log(`[${dvn.name}] Packet not verified. Calling verifyPacket on DVN contract...`);
                
                const txResult = await dvn.walletClient.writeContract({
                    address: dvn.address,
                    abi: dvnContractABI,
                    functionName: "verifyPacket",
                    args: [packetData.packetHeader, packetData.payloadHash, ulnConfig.confirmations]
                });
                
                console.log(`[${dvn.name}] verifyPacket transaction sent:`, txResult);
                
                // Wait for the transaction to be confirmed
                await dvn.publicClient.waitForTransactionReceipt({
                    hash: txResult,
                });
                
                // Verify the packet was actually verified
                verified = await dvn.publicClient.readContract({
                    address: dvn.address,
                    abi: dvnContractABI,
                    functionName: "verified",
                    args: [packetData.packetHeader, packetData.payloadHash]
                });
                
                console.log(`[${dvn.name}] Packet verification status after verifyPacket: ${verified}`);
                
                if (!verified) {
                    console.log(`[${dvn.name}] Packet still not verified after calling verifyPacket.`);
                } else {
                    console.log(`[${dvn.name}] ✅ Packet successfully verified!`);
                }
            } else {
                console.log(`[${dvn.name}] ✅ Packet already verified!`);
            }
            
        } catch (error) {
            console.error(`[${dvn.name}] Error during verification:`, error);
        }
    }
    
    /**
     * Get DVN instance by address
     */
    getDVNByAddress(address: string): DVNInstance | undefined {
        return this.dvnInstances.get(address.toLowerCase());
    }
    
    /**
     * Get all available DVN instances
     */
    getAllDVNs(): DVNInstance[] {
        return Array.from(this.dvnInstances.values());
    }
    
    /**
     * Check if a DVN is available
     */
    isDVNAvailable(address: string): boolean {
        return this.dvnInstances.has(address.toLowerCase());
    }
}
