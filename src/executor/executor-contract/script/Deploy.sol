// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {SimpleExecutor} from "../src/SimpleExecutor.sol";
import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

contract DeploySimpleExecutor is Script {
    struct Deployment {
        string name;
        uint32 eid;
        uint256 execFee;
        uint256 forkId;
        SimpleExecutor executor;
    }
    Deployment[] public deployments;

    function run() public {
        // Use the deployer's private key from the environment.
        uint256 deployer = vm.envUint("PRIVATE_KEY");

        // Read the comma-separated list of network names (e.g. "core,celo,gnosis")
        string memory networksStr = vm.envString("NETWORKS");
        string[] memory networks = split(networksStr, ",");

        for (uint256 i = 0; i < networks.length; i++) {
            string memory net = networks[i];
            // Convert the network name to uppercase for environment variable lookup.
            string memory netUpper = toUpper(net);

            // Get the RPC URL, endpoint, EID, and execution fee for this network.
            string memory rpc = vm.envString(string(abi.encodePacked("RPC_", netUpper)));
            address endpointAddr = vm.envAddress(string(abi.encodePacked("ENDPOINT_", netUpper)));
            uint32 eid = uint32(vm.envUint(string(abi.encodePacked("EID_", netUpper))));
            uint256 execFee = vm.envUint(string(abi.encodePacked("EXEC_FEE_", netUpper)));

            // Create a fork using the provided RPC URL.
            // When you run the script with --skip-simulation, transactions will be sent to the live network.
            uint256 forkId = vm.createSelectFork(rpc);
            vm.selectFork(forkId);

            // Build fee arrays for the executor.
            // For each network, the SimpleExecutor’s constructor requires arrays of (destination EIDs, fee)
            // for every network except its own.
            uint256 numOther = networks.length - 1;
            uint32[] memory dstEids = new uint32[](numOther);
            uint256[] memory fees = new uint256[](numOther);
            uint256 index = 0;
            for (uint256 j = 0; j < networks.length; j++) {
                if (j == i) continue;
                string memory otherNet = networks[j];
                string memory otherNetUpper = toUpper(otherNet);
                uint32 otherEid = uint32(vm.envUint(string(abi.encodePacked("EID_", otherNetUpper))));
                uint256 otherFee = vm.envUint(string(abi.encodePacked("EXEC_FEE_", otherNetUpper)));
                dstEids[index] = otherEid;
                fees[index] = otherFee;
                index++;
            }

            // Deploy the SimpleExecutor on the actual network.
            vm.startBroadcast(deployer);
            SimpleExecutor executor = new SimpleExecutor(
                ILayerZeroEndpointV2(endpointAddr),
                dstEids,
                fees
            );
            vm.stopBroadcast();

            deployments.push(Deployment({
                name: net,
                eid: eid,
                execFee: execFee,
                forkId: forkId,
                executor: executor
            }));
        }

        // Log the deployed contract addresses for each network.
        for (uint256 i = 0; i < deployments.length; i++) {
            Deployment memory d = deployments[i];
            console2.log("Network:", d.name);
            console2.log("  Executor deployed at:", address(d.executor));
        }
    }

    /// @dev Converts an ASCII string to uppercase (only supports letters a–z).
    function toUpper(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bUpper = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            uint8 char = uint8(bStr[i]);
            // Convert a-z (97–122) to A-Z (65–90).
            if (char >= 97 && char <= 122) {
                bUpper[i] = bytes1(char - 32);
            } else {
                bUpper[i] = bStr[i];
            }
        }
        return string(bUpper);
    }

    /// @dev Splits string `s` by delimiter `delimiter` and returns an array of substrings.
    function split(string memory s, string memory delimiter) internal pure returns (string[] memory) {
        bytes memory sBytes = bytes(s);
        bytes memory delimiterBytes = bytes(delimiter);
        uint256 partsCount = 1;
        for (uint256 i = 0; i < sBytes.length; i++) {
            bool isMatch = true;
            for (uint256 j = 0; j < delimiterBytes.length; j++) {
                if (i + j >= sBytes.length || sBytes[i + j] != delimiterBytes[j]) {
                    isMatch = false;
                    break;
                }
            }
            if (isMatch) {
                partsCount++;
                i += delimiterBytes.length - 1;
            }
        }
        string[] memory parts = new string[](partsCount);
        uint256 partIndex = 0;
        uint256 start = 0;
        for (uint256 i = 0; i < sBytes.length; i++) {
            bool isMatch = true;
            for (uint256 j = 0; j < delimiterBytes.length; j++) {
                if (i + j >= sBytes.length || sBytes[i + j] != delimiterBytes[j]) {
                    isMatch = false;
                    break;
                }
            }
            if (isMatch) {
                bytes memory part = new bytes(i - start);
                for (uint256 k = start; k < i; k++) {
                    part[k - start] = sBytes[k];
                }
                parts[partIndex] = string(part);
                partIndex++;
                i += delimiterBytes.length - 1;
                start = i + 1;
            }
        }
        // Rename the second variable to avoid shadowing.
        bytes memory lastPart = new bytes(sBytes.length - start);
        for (uint256 i = start; i < sBytes.length; i++) {
            lastPart[i - start] = sBytes[i];
        }
        parts[partIndex] = string(lastPart);
        return parts;
    }
}