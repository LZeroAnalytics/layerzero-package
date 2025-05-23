export const abi = [
    {
        "type": "constructor",
        "inputs": [
            {
                "name": "_endpoint",
                "type": "address",
                "internalType": "contract ILayerZeroEndpointV2"
            },
            {
                "name": "_receiveMessageLib",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_sendMessageLib",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_dstEids",
                "type": "uint32[]",
                "internalType": "uint32[]"
            },
            {
                "name": "_fees",
                "type": "uint256[]",
                "internalType": "uint256[]"
            }
        ],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "assignJob",
        "inputs": [
            {
                "name": "_param",
                "type": "tuple",
                "internalType": "struct ILayerZeroDVN.AssignJobParam",
                "components": [
                    {
                        "name": "dstEid",
                        "type": "uint32",
                        "internalType": "uint32"
                    },
                    {
                        "name": "packetHeader",
                        "type": "bytes",
                        "internalType": "bytes"
                    },
                    {
                        "name": "payloadHash",
                        "type": "bytes32",
                        "internalType": "bytes32"
                    },
                    {
                        "name": "confirmations",
                        "type": "uint64",
                        "internalType": "uint64"
                    },
                    {
                        "name": "sender",
                        "type": "address",
                        "internalType": "address"
                    }
                ]
            },
            {
                "name": "_options",
                "type": "bytes",
                "internalType": "bytes"
            }
        ],
        "outputs": [
            {
                "name": "fee",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "payable"
    },
    {
        "type": "function",
        "name": "endpoint",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "contract ILayerZeroEndpointV2"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getFee",
        "inputs": [
            {
                "name": "_dstEid",
                "type": "uint32",
                "internalType": "uint32"
            },
            {
                "name": "_confirmations",
                "type": "uint64",
                "internalType": "uint64"
            },
            {
                "name": "_sender",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_options",
                "type": "bytes",
                "internalType": "bytes"
            }
        ],
        "outputs": [
            {
                "name": "fee",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "messageFees",
        "inputs": [
            {
                "name": "",
                "type": "uint32",
                "internalType": "uint32"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "owner",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "receiveMessageLib",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "renounceOwnership",
        "inputs": [],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "sendMessageLib",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "setMessageFee",
        "inputs": [
            {
                "name": "dstEid",
                "type": "uint32",
                "internalType": "uint32"
            },
            {
                "name": "fee",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "transferOwnership",
        "inputs": [
            {
                "name": "newOwner",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "verified",
        "inputs": [
            {
                "name": "_packetHeader",
                "type": "bytes",
                "internalType": "bytes"
            },
            {
                "name": "_payloadHash",
                "type": "bytes32",
                "internalType": "bytes32"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "bool",
                "internalType": "bool"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "verifiedPackets",
        "inputs": [
            {
                "name": "",
                "type": "bytes32",
                "internalType": "bytes32"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "bool",
                "internalType": "bool"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "verifyPacket",
        "inputs": [
            {
                "name": "_packetHeader",
                "type": "bytes",
                "internalType": "bytes"
            },
            {
                "name": "_payloadHash",
                "type": "bytes32",
                "internalType": "bytes32"
            },
            {
                "name": "_confirmations",
                "type": "uint64",
                "internalType": "uint64"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "event",
        "name": "MessageFeeSet",
        "inputs": [
            {
                "name": "dstEid",
                "type": "uint32",
                "indexed": true,
                "internalType": "uint32"
            },
            {
                "name": "messageFee",
                "type": "uint256",
                "indexed": false,
                "internalType": "uint256"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "OwnershipTransferred",
        "inputs": [
            {
                "name": "previousOwner",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "newOwner",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            }
        ],
        "anonymous": false
    },
    {
        "type": "error",
        "name": "OwnableInvalidOwner",
        "inputs": [
            {
                "name": "owner",
                "type": "address",
                "internalType": "address"
            }
        ]
    },
    {
        "type": "error",
        "name": "OwnableUnauthorizedAccount",
        "inputs": [
            {
                "name": "account",
                "type": "address",
                "internalType": "address"
            }
        ]
    }
]as const;