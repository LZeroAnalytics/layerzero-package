/**
 * The LZMessageEvent represents an event produced by the event provider.
 * You should adjust the types below to match your actual packet structure.
 */
export type LZMessageEvent = {
    packet: {
        srcEid: number;
        sender: string;
        nonce: number;
        receiver: string;
        guid: string;
        message: string;
    };
    packetHeader: `0x${string}`;
    payloadHash: `0x${string}`;
    rawPayload: `0x${string}`;
    transactionHash: string;
};
