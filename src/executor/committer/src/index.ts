// src/index.ts
import { createPublicClient, http } from "viem";
import {mainnet} from "viem/chains";
import { config as dotenvConfig } from "dotenv";
import { LayerZeroCommitter, LZMessageEvent } from "./LayerZeroCommitter";

// Load environment variables from .env file.
dotenvConfig();

async function main() {
    const client = createPublicClient({
        chain: mainnet,
        transport: http(process.env.RPC_URL!),
    });

    const committer = new LayerZeroCommitter(client);

    // Start watching for events.
    const stop = committer.start((event: LZMessageEvent) => {
        console.log("Received event:", event);
    });

    console.log("LayerZero Committer is now listening for events...");
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});