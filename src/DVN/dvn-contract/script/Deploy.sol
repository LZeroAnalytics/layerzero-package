// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {LayerZeroDVNContract} from "../src/DVNContract.sol";
import {ILayerZeroEndpointV2} from "../lib/layerzero-v2/packages/layerzero-v2/evm/protocol/contracts/interfaces/ILayerZeroEndpointV2.sol";

contract DeployDVNContract is Script {
    function run() public {
        // Retrieve the deployer's private key and network information from env variables.
        uint256 deployer = vm.envUint("PRIVATE_KEY");
        string memory activeNetwork = vm.envString("NETWORK");

        // Retrieve active network parameters.
        address endpointAddr = vm.envAddress("ENDPOINT");
        address sendMessageLibAddr = vm.envAddress("TRUSTED_SEND_LIB");
        address receiveMessageLibAddr = vm.envAddress("TRUSTED_RECEIVE_LIB");

        // Read comma-separated lists for destination EIDs and fees.
        string memory dstEidsStr = vm.envString("DST_EIDS");
        string memory feesStr = vm.envString("FEES");

        uint32[] memory dstEids = parseUint32Array(dstEidsStr);
        uint256[] memory feeArray = parseUint256Array(feesStr);
        require(dstEids.length == feeArray.length, "Arrays length mismatch");

        // Start the broadcast and deploy the DVN contract.
        vm.startBroadcast(deployer);
        LayerZeroDVNContract dvn = new LayerZeroDVNContract(
            ILayerZeroEndpointV2(endpointAddr),
            receiveMessageLibAddr,
            sendMessageLibAddr,
            dstEids,
            feeArray
        );
        vm.stopBroadcast();

        console2.log("Active Network:", activeNetwork);
        console2.log("DVN deployed at:", address(dvn));
    }

    /// @dev Splits a comma-separated string and converts each part into a uint32.
    function parseUint32Array(string memory s) internal pure returns (uint32[] memory) {
        string[] memory parts = split(s, ",");
        uint32[] memory arr = new uint32[](parts.length);
        for (uint i = 0; i < parts.length; i++) {
            arr[i] = uint32(parseUint(parts[i]));
        }
        return arr;
    }

    /// @dev Splits a comma-separated string and converts each part into a uint256.
    function parseUint256Array(string memory s) internal pure returns (uint256[] memory) {
        string[] memory parts = split(s, ",");
        uint256[] memory arr = new uint256[](parts.length);
        for (uint i = 0; i < parts.length; i++) {
            arr[i] = parseUint(parts[i]);
        }
        return arr;
    }

    /// @dev Converts a numeric string to a uint256.
    function parseUint(string memory s) internal pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 number = 0;
        for (uint i = 0; i < b.length; i++){
            uint8 digit = uint8(b[i]) - 48;
            require(digit <= 9, "Invalid character in uint string");
            number = number * 10 + digit;
        }
        return number;
    }

    /// @dev Splits string `s` by the delimiter `delimiter` and returns an array of substrings.
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
        bytes memory lastPart = new bytes(sBytes.length - start);
        for (uint256 i = start; i < sBytes.length; i++) {
            lastPart[i - start] = sBytes[i];
        }
        parts[partIndex] = string(lastPart);
        return parts;
    }
}