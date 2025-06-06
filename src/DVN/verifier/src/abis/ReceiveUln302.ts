export const abi = [
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "_endpoint",
                "type": "address"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "inputs": [],
        "name": "LZ_MessageLib_OnlyEndpoint",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "LZ_ULN_AtLeastOneDVN",
        "type": "error"
    },
    {
        "inputs": [
            {
                "internalType": "uint32",
                "name": "configType",
                "type": "uint32"
            }
        ],
        "name": "LZ_ULN_InvalidConfigType",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "LZ_ULN_InvalidConfirmations",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "LZ_ULN_InvalidEid",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "LZ_ULN_InvalidOptionalDVNCount",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "LZ_ULN_InvalidOptionalDVNThreshold",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "LZ_ULN_InvalidPacketHeader",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "LZ_ULN_InvalidPacketVersion",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "LZ_ULN_InvalidRequiredDVNCount",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "LZ_ULN_Unsorted",
        "type": "error"
    },
    {
        "inputs": [
            {
                "internalType": "uint32",
                "name": "eid",
                "type": "uint32"
            }
        ],
        "name": "LZ_ULN_UnsupportedEid",
        "type": "error"
    },
    {
        "inputs": [],
        "name": "LZ_ULN_Verifying",
        "type": "error"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "components": [
                    {
                        "internalType": "uint32",
                        "name": "eid",
                        "type": "uint32"
                    },
                    {
                        "components": [
                            {
                                "internalType": "uint64",
                                "name": "confirmations",
                                "type": "uint64"
                            },
                            {
                                "internalType": "uint8",
                                "name": "requiredDVNCount",
                                "type": "uint8"
                            },
                            {
                                "internalType": "uint8",
                                "name": "optionalDVNCount",
                                "type": "uint8"
                            },
                            {
                                "internalType": "uint8",
                                "name": "optionalDVNThreshold",
                                "type": "uint8"
                            },
                            {
                                "internalType": "address[]",
                                "name": "requiredDVNs",
                                "type": "address[]"
                            },
                            {
                                "internalType": "address[]",
                                "name": "optionalDVNs",
                                "type": "address[]"
                            }
                        ],
                        "internalType": "struct UlnConfig",
                        "name": "config",
                        "type": "tuple"
                    }
                ],
                "indexed": false,
                "internalType": "struct SetDefaultUlnConfigParam[]",
                "name": "params",
                "type": "tuple[]"
            }
        ],
        "name": "DefaultUlnConfigsSet",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "address",
                "name": "previousOwner",
                "type": "address"
            },
            {
                "indexed": true,
                "internalType": "address",
                "name": "newOwner",
                "type": "address"
            }
        ],
        "name": "OwnershipTransferred",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": false,
                "internalType": "address",
                "name": "dvn",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "bytes",
                "name": "header",
                "type": "bytes"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "confirmations",
                "type": "uint256"
            },
            {
                "indexed": false,
                "internalType": "bytes32",
                "name": "proofHash",
                "type": "bytes32"
            }
        ],
        "name": "PayloadVerified",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": false,
                "internalType": "address",
                "name": "oapp",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "uint32",
                "name": "eid",
                "type": "uint32"
            },
            {
                "components": [
                    {
                        "internalType": "uint64",
                        "name": "confirmations",
                        "type": "uint64"
                    },
                    {
                        "internalType": "uint8",
                        "name": "requiredDVNCount",
                        "type": "uint8"
                    },
                    {
                        "internalType": "uint8",
                        "name": "optionalDVNCount",
                        "type": "uint8"
                    },
                    {
                        "internalType": "uint8",
                        "name": "optionalDVNThreshold",
                        "type": "uint8"
                    },
                    {
                        "internalType": "address[]",
                        "name": "requiredDVNs",
                        "type": "address[]"
                    },
                    {
                        "internalType": "address[]",
                        "name": "optionalDVNs",
                        "type": "address[]"
                    }
                ],
                "indexed": false,
                "internalType": "struct UlnConfig",
                "name": "config",
                "type": "tuple"
            }
        ],
        "name": "UlnConfigSet",
        "type": "event"
    },
    {
        "inputs": [
            {
                "internalType": "bytes",
                "name": "_packetHeader",
                "type": "bytes"
            },
            {
                "internalType": "uint32",
                "name": "_localEid",
                "type": "uint32"
            }
        ],
        "name": "assertHeader",
        "outputs": [],
        "stateMutability": "pure",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "bytes",
                "name": "_packetHeader",
                "type": "bytes"
            },
            {
                "internalType": "bytes32",
                "name": "_payloadHash",
                "type": "bytes32"
            }
        ],
        "name": "commitVerification",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "_oapp",
                "type": "address"
            },
            {
                "internalType": "uint32",
                "name": "_remoteEid",
                "type": "uint32"
            }
        ],
        "name": "getAppUlnConfig",
        "outputs": [
            {
                "components": [
                    {
                        "internalType": "uint64",
                        "name": "confirmations",
                        "type": "uint64"
                    },
                    {
                        "internalType": "uint8",
                        "name": "requiredDVNCount",
                        "type": "uint8"
                    },
                    {
                        "internalType": "uint8",
                        "name": "optionalDVNCount",
                        "type": "uint8"
                    },
                    {
                        "internalType": "uint8",
                        "name": "optionalDVNThreshold",
                        "type": "uint8"
                    },
                    {
                        "internalType": "address[]",
                        "name": "requiredDVNs",
                        "type": "address[]"
                    },
                    {
                        "internalType": "address[]",
                        "name": "optionalDVNs",
                        "type": "address[]"
                    }
                ],
                "internalType": "struct UlnConfig",
                "name": "",
                "type": "tuple"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint32",
                "name": "_eid",
                "type": "uint32"
            },
            {
                "internalType": "address",
                "name": "_oapp",
                "type": "address"
            },
            {
                "internalType": "uint32",
                "name": "_configType",
                "type": "uint32"
            }
        ],
        "name": "getConfig",
        "outputs": [
            {
                "internalType": "bytes",
                "name": "",
                "type": "bytes"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "_oapp",
                "type": "address"
            },
            {
                "internalType": "uint32",
                "name": "_remoteEid",
                "type": "uint32"
            }
        ],
        "name": "getUlnConfig",
        "outputs": [
            {
                "components": [
                    {
                        "internalType": "uint64",
                        "name": "confirmations",
                        "type": "uint64"
                    },
                    {
                        "internalType": "uint8",
                        "name": "requiredDVNCount",
                        "type": "uint8"
                    },
                    {
                        "internalType": "uint8",
                        "name": "optionalDVNCount",
                        "type": "uint8"
                    },
                    {
                        "internalType": "uint8",
                        "name": "optionalDVNThreshold",
                        "type": "uint8"
                    },
                    {
                        "internalType": "address[]",
                        "name": "requiredDVNs",
                        "type": "address[]"
                    },
                    {
                        "internalType": "address[]",
                        "name": "optionalDVNs",
                        "type": "address[]"
                    }
                ],
                "internalType": "struct UlnConfig",
                "name": "rtnConfig",
                "type": "tuple"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "bytes32",
                "name": "headerHash",
                "type": "bytes32"
            },
            {
                "internalType": "bytes32",
                "name": "payloadHash",
                "type": "bytes32"
            },
            {
                "internalType": "address",
                "name": "dvn",
                "type": "address"
            }
        ],
        "name": "hashLookup",
        "outputs": [
            {
                "internalType": "bool",
                "name": "submitted",
                "type": "bool"
            },
            {
                "internalType": "uint64",
                "name": "confirmations",
                "type": "uint64"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "uint32",
                "name": "_eid",
                "type": "uint32"
            }
        ],
        "name": "isSupportedEid",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "messageLibType",
        "outputs": [
            {
                "internalType": "enum MessageLibType",
                "name": "",
                "type": "uint8"
            }
        ],
        "stateMutability": "pure",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "owner",
        "outputs": [
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "renounceOwnership",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "_oapp",
                "type": "address"
            },
            {
                "components": [
                    {
                        "internalType": "uint32",
                        "name": "eid",
                        "type": "uint32"
                    },
                    {
                        "internalType": "uint32",
                        "name": "configType",
                        "type": "uint32"
                    },
                    {
                        "internalType": "bytes",
                        "name": "config",
                        "type": "bytes"
                    }
                ],
                "internalType": "struct SetConfigParam[]",
                "name": "_params",
                "type": "tuple[]"
            }
        ],
        "name": "setConfig",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "components": [
                    {
                        "internalType": "uint32",
                        "name": "eid",
                        "type": "uint32"
                    },
                    {
                        "components": [
                            {
                                "internalType": "uint64",
                                "name": "confirmations",
                                "type": "uint64"
                            },
                            {
                                "internalType": "uint8",
                                "name": "requiredDVNCount",
                                "type": "uint8"
                            },
                            {
                                "internalType": "uint8",
                                "name": "optionalDVNCount",
                                "type": "uint8"
                            },
                            {
                                "internalType": "uint8",
                                "name": "optionalDVNThreshold",
                                "type": "uint8"
                            },
                            {
                                "internalType": "address[]",
                                "name": "requiredDVNs",
                                "type": "address[]"
                            },
                            {
                                "internalType": "address[]",
                                "name": "optionalDVNs",
                                "type": "address[]"
                            }
                        ],
                        "internalType": "struct UlnConfig",
                        "name": "config",
                        "type": "tuple"
                    }
                ],
                "internalType": "struct SetDefaultUlnConfigParam[]",
                "name": "_params",
                "type": "tuple[]"
            }
        ],
        "name": "setDefaultUlnConfigs",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "bytes4",
                "name": "_interfaceId",
                "type": "bytes4"
            }
        ],
        "name": "supportsInterface",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "newOwner",
                "type": "address"
            }
        ],
        "name": "transferOwnership",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "components": [
                    {
                        "internalType": "uint64",
                        "name": "confirmations",
                        "type": "uint64"
                    },
                    {
                        "internalType": "uint8",
                        "name": "requiredDVNCount",
                        "type": "uint8"
                    },
                    {
                        "internalType": "uint8",
                        "name": "optionalDVNCount",
                        "type": "uint8"
                    },
                    {
                        "internalType": "uint8",
                        "name": "optionalDVNThreshold",
                        "type": "uint8"
                    },
                    {
                        "internalType": "address[]",
                        "name": "requiredDVNs",
                        "type": "address[]"
                    },
                    {
                        "internalType": "address[]",
                        "name": "optionalDVNs",
                        "type": "address[]"
                    }
                ],
                "internalType": "struct UlnConfig",
                "name": "_config",
                "type": "tuple"
            },
            {
                "internalType": "bytes32",
                "name": "_headerHash",
                "type": "bytes32"
            },
            {
                "internalType": "bytes32",
                "name": "_payloadHash",
                "type": "bytes32"
            }
        ],
        "name": "verifiable",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "bytes",
                "name": "_packetHeader",
                "type": "bytes"
            },
            {
                "internalType": "bytes32",
                "name": "_payloadHash",
                "type": "bytes32"
            },
            {
                "internalType": "uint64",
                "name": "_confirmations",
                "type": "uint64"
            }
        ],
        "name": "verify",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "version",
        "outputs": [
            {
                "internalType": "uint64",
                "name": "major",
                "type": "uint64"
            },
            {
                "internalType": "uint8",
                "name": "minor",
                "type": "uint8"
            },
            {
                "internalType": "uint8",
                "name": "endpointVersion",
                "type": "uint8"
            }
        ],
        "stateMutability": "pure",
        "type": "function"
    }
] as const;