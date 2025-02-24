export type Packet = {
    version: number;
    nonce: string | number;
    srcEid: number;
    sender: `0x${string}`;
    dstEid: number;
    receiver: `0x${string}`;
    guid: `0x${string}`;
    message: `0x${string}`;
    payload: `0x${string}`;
};

export type LZRawEvent = {
    type: "raw";
    packet: Packet;
    packetHeader: `0x${string}`;
    payloadHash: `0x${string}`;
    rawPayload: `0x${string}`;
    transactionHash: string;
};

export type LZVerifiedEvent = {
    type: "verified";
    header: `0x${string}`;  // This should match the packetHeader from the raw event
    confirmations: string | number | bigint;
    transactionHash: string;
};

export type LZMessageEvent = LZRawEvent | LZVerifiedEvent;
