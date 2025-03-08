import { PublicClient } from "viem";
import { RedisClientType } from "redis";
import { sourceConfig } from "../config";
import { abi as dvnABI } from "../abis/DVNContract";

export class JobAssignedWatcher {
    constructor(
        private client: PublicClient,
        private redisClient: RedisClientType<any, any>
    ) {}

    start() {
        console.log("Starting JobAssignedWatcher...");

        // Listen for JobAssigned events from the DVN contract
        this.client.watchContractEvent({
            address: sourceConfig.dvn,
            abi: dvnABI,
            eventName: "JobAssigned",
            onLogs: async (logs) => {
                for (const log of logs) {
                    console.log("JobAssigned event detected, tx:", log.transactionHash);
                    await this.handleJobAssigned(log);
                }
            }
        });
    }

    private async handleJobAssigned(log: any): Promise<void> {
        // Cast log to any to access .args safely
        const { key, fee } = (log as any).args;
        console.log(`Processing JobAssigned event with key: ${key} and fee: ${fee}`);

        // Retrieve the corresponding PacketSent event from Redis (stored under key `packet:${key}`)
        const redisKey = `packet:${key}`;
        const packetData = await this.redisClient.get(redisKey);
        if (!packetData) {
            console.log(`No matching PacketSent event found in Redis for key: ${key}`);
            return;
        }
        const packetEvent = JSON.parse(packetData);
        // Build a job assignment message
        const message = {
            key,
            fee: fee.toString(),
            packetEvent,
            status: "job_assigned",
            timestamp: new Date().toISOString()
        };
        await this.redisClient.publish("jobAssignment", JSON.stringify(message));
        console.log(`JobAssignment message published for key: ${key}`);
    }
}