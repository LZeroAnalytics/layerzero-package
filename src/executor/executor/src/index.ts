// src/index.ts
import { config as dotenvConfig } from "dotenv";
import {Account, Chain, createWalletClient, http, HttpTransport, WalletClient} from "viem";
import { mainnet } from "viem/chains";
import { chainConfig } from "./config";
import { privateKeyToAccount } from "viem/accounts";
import { LayerZeroExecutor } from "./LayerZeroExecutor";
import { LZMessageEvent } from "./types";

// Load environment variables
dotenvConfig();

// Create a wallet client for the chain defined in config
const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);
const client: WalletClient<HttpTransport, Chain, Account> = createWalletClient({
    chain: mainnet,
    transport: http(chainConfig.rpc),
    account,
});

async function main() {
    const executor = new LayerZeroExecutor(chainConfig, client);
    const stop = executor.start();

    // For demonstration, we add a dummy event after 5 seconds.
    setTimeout(() => {
        const dummyEvent: LZMessageEvent = {
            packet: {
                srcEid: 30101,
                sender: "0x0000000000000000000000000000000000000000",
                nonce: 1,
                receiver: "0x0000000000000000000000000000000000000000",
                guid: "0xabcdef",
                message: "0x",
            },
            packetHeader: "0xabcdef",
            payloadHash: "0x123456",
            rawPayload: "0x",
            transactionHash: "0xdeadbeef",
        };
        console.log("Adding dummy event to executor.");
        executor.addEvent(dummyEvent);
    }, 5000);
}

main().catch((e) => console.error(e));
