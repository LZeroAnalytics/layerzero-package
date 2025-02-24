/**
 * The LZMessageEvent represents an event produced by the event provider.
 * You should adjust the types below to match your actual packet structure.
 */
export type LZMessageEvent = {
    packet: Packet;
    packetHeader: `0x${string}`;
    payloadHash: `0x${string}`;
    rawPayload: `0x${string}`;
    transactionHash: string;
};

export type PacketPath = {
    srcEid: number;
    sender: `0x${string}`;
    dstEid: number;
    receiver: `0x${string}`;
};

export type PacketHeader = {
    version: number;
    nonce: bigint;
} & PacketPath;

export type Packet = PacketHeader & {
    guid: `0x${string}`;
    message: `0x${string}`;
    payload: `0x${string}`;
};