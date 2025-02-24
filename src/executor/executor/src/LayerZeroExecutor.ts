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
import { abi as executorABI } from "./abis/SimpleExecutor";
import { abi as endpointViewABI } from "./abis/EndpointV2View";
import { abi as receiveLibViewABI } from "./abis/ReceiveUln302View";
import { abi as receiveLibABI } from "./abis/ReceiveUln302";
import { ChainConfig } from "./config";
import { LZMessageEvent } from "./types";

import {
    bytes32ToEthAddress, hexZeroPadTo32,
} from "@layerzerolabs/lz-v2-utilities";

// The ExecutionState is an enum defined by the EndpointV2View contract.
export enum ExecutionState {
    NotExecutable = 0,
    VerifiedButNotExecutable = 1,
    Executable = 2,
    Executed = 3,
}

// Part of the ReceiveLib.
export enum VerificationState {
    Verifying = 0,
    Verifiable = 1,
    Verified = 2,
    NotInitializable = 3,
}

const DEFAULT_GAS_LIMIT = 1_000_000;

export class LayerZeroExecutor {
    active: boolean = false;
    pendingEvents: LZMessageEvent[] = [];

    endpointContract: GetContractReturnType<
        typeof endpointABI,
        WalletClient<HttpTransport, Chain>,
        `0x${string}`
    >;
    endpointViewContract: GetContractReturnType<
        typeof endpointViewABI,
        WalletClient<HttpTransport, Chain>,
        `0x${string}`
    >;
    executorContract: GetContractReturnType<
        typeof executorABI,
        WalletClient<HttpTransport, Chain>,
        `0x${string}`
    >;
    receiveLibViewContract: GetContractReturnType<
        typeof receiveLibViewABI,
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

        this.endpointViewContract = getContract({
            address: config.endpointView,
            abi: endpointViewABI,
            client,
        });

        this.executorContract = getContract({
            address: config.executor,
            abi: executorABI,
            client,
        });

        this.receiveLibViewContract = getContract({
            address: config.trustedReceiveLibView,
            abi: receiveLibViewABI,
            client,
        });

        this.receiveLibContract = getContract({
            address: config.trustedReceiveLib,
            abi: receiveLibABI,
            client,
        });
    }

    addEvent(event: LZMessageEvent) {
        console.log(`Adding event ${event.transactionHash} to executor.`);
        this.pendingEvents.push(event);
    }

    start(): () => void {
        if (this.active) throw new Error("Executor already active");
        this.active = true;

        this.startAsync().then(() => {
            console.log("Executor processing loop finished.");
        });

        return () => {
            this.active = false;
        };
    }

    async startAsync() {
        while (this.active) {
            const event = this.pendingEvents.shift();
            let wait = this.pendingEvents.length === 0 ? 5000 : 500;
            if (event) {
                try {
                    await this.executeOrRequeueEvent(event);
                } catch (e) {
                    this.pendingEvents.push(event);
                    console.error(`Error in executor loop: ${e}. Waiting 30 seconds.`);
                    wait = 30000;
                }
            }
            await new Promise((resolve) => setTimeout(resolve, wait));
        }
        console.log("Executor stopped.");
    }

    async executeOrRequeueEvent(event: LZMessageEvent) {
        //const executionState = await this.getExecutionState(event);
        //console.log(`Event ${event.transactionHash} execution state: ${executionState}`);

        await this.commitEvent(event);
        await this.executeEvent(event);
        return;

        /*const verificationState = await this.getVerificationState(event);
        if (verificationState === VerificationState.Verifiable) {
            await this.commitEvent(event);
            this.pendingEvents.push(event);
            return;
        }

        if (executionState === ExecutionState.VerifiedButNotExecutable) {
            console.log(`Event ${event.transactionHash} verified but not executable, requeuing.`);
            this.pendingEvents.push(event);
            return;
        }

        console.log(`Event ${event.transactionHash} not committable yet, requeuing.`);
        this.pendingEvents.push(event);

         */
    }

    /*
    curl -X POST https://781cbbb48cf94684a60163c6edb59b5e-rpc.dev.lzeroanalytics.com \
-H "Content-Type: application/json" \
-d '{
  "jsonrpc": "2.0",
  "method": "debug_traceTransaction",
  "params": ["0xcd9fbafd96ae48da44b333dfaa392f48049104b1fd360d414a9872f9f19f145f", {}],
  "id": 1
}'

curl -X POST https://781cbbb48cf94684a60163c6edb59b5e-rpc.dev.lzeroanalytics.com \
-H "Content-Type: application/json" \
-d '{"jsonrpc":"2.0","method":"eth_getTransactionByHash","params":["0xcd9fbafd96ae48da44b333dfaa392f48049104b1fd360d414a9872f9f19f145f"],"id":1}'


     */

    async executeEvent(event: LZMessageEvent) {
        console.log(`Executing event ${event.transactionHash}`);
        const origin = {
            srcEid: Number(event.packet.srcEid),
            sender: padHex(event.packet.sender),
            nonce: BigInt(event.packet.nonce),
        };
        const receiver = bytes32ToEthAddress(event.packet.receiver) as `0x${string}`;
        const guid = hexZeroPadTo32(event.packet.guid) as `0x${string}`;
        const message = event.packet.message;
        const extraData = "0x";

        const tx = await this.endpointContract.write.lzReceive(
            [origin,
            receiver,
            guid,
            message,
            extraData],
            {
                gas: BigInt(DEFAULT_GAS_LIMIT),
                account: this.client.account,
            }
        );
        console.log(`Executed event: ${tx}`);
    }

    async commitEvent(event: LZMessageEvent) {
        console.log(`Committing event ${event.transactionHash}`);
        const res = await this.receiveLibContract.write.commitVerification(
            [event.packetHeader, event.payloadHash],
            {
                gas: BigInt(DEFAULT_GAS_LIMIT),
                account: this.client.account,
            }
        );
        console.log(`Committed event: ${res}`);
    }

    async getExecutionState(event: LZMessageEvent): Promise<ExecutionState> {
        console.log("Running executable", event.packet.srcEid, padHex(event.packet.sender), BigInt(event.packet.nonce), event.packet.receiver as `0x${string}`);
        const state: number = await this.endpointViewContract.read.executable([
            {
                srcEid: event.packet.srcEid,
                sender: padHex(event.packet.sender),
                nonce: BigInt(event.packet.nonce),
            },
            event.packet.receiver as `0x${string}`,
        ]);
        return state;
    }

    async getVerificationState(event: LZMessageEvent): Promise<VerificationState> {
        const state: number = (await this.receiveLibViewContract.read.verifiable([
            event.packetHeader,
            event.payloadHash,
        ])) as number;
        return state;
    }
}