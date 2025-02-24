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
                "name": "_receiveLib",
                "type": "address",
                "internalType": "address"
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
        "name": "assignedJobs",
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
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
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
        "name": "feePerJob",
        "inputs": [],
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
        "name": "receiveLib",
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
        "name": "JobAssigned",
        "inputs": [
            {
                "name": "dvn",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "key",
                "type": "bytes32",
                "indexed": true,
                "internalType": "bytes32"
            },
            {
                "name": "fee",
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
]