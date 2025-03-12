import {Account, HttpTransport, padHex, WalletClient} from 'viem';
import {Chain} from 'viem/chains';
import {config as dotenvConfig} from 'dotenv';
import {abi as endpointABI} from "./abis/EndpointV2";
import {RedisClientType} from "redis";
import {chainConfig} from "./config";
import {bytes32ToEthAddress, hexZeroPadTo32} from "@layerzerolabs/lz-v2-utilities";

dotenvConfig();

export class LayerZeroExecutor {
    constructor(
        private walletClient: WalletClient<HttpTransport, Chain, Account>,
        private redisClient: RedisClientType<any, any>
    ) {}

    async start() {
        console.log('Starting Redis subscription for execution events...');
        // Subscribe to the 'execution' channel
        const subscription = this.redisClient.subscribe('execution', async (message: string) => {
            console.log('Execution event received:', message);
            try {
                const execution: any = JSON.parse(message);
                await this.processExecution(execution);
            } catch (error) {
                console.error('Error processing execution event:', error);
            }
        });
    }

    private async processExecution(execution: any): Promise<void> {
        console.log('Processing execution:', execution);

        const packet = execution.packetData.packet;
        const origin = {
            srcEid: Number(packet.srcEid),
            sender: padHex(packet.sender),
            nonce: BigInt(packet.nonce),
        };
        const receiver = bytes32ToEthAddress(packet.receiver) as `0x${string}`;
        const guid = hexZeroPadTo32(packet.guid) as `0x${string}`;
        const message = packet.message;
        const extraData = "0x";

        const txResult = await this.walletClient.writeContract({
            address: chainConfig.endpoint,
            abi: endpointABI,
            functionName: "lzReceive",
            args: [origin, receiver, guid, message, extraData],
        });

        console.log("Execution submitted:", txResult)
    }
}