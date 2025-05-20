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

        // Start the broadcast and deploy the DVN contract.
        vm.startBroadcast(deployer);
        LayerZeroDVNContract dvn = new LayerZeroDVNContract(
            ILayerZeroEndpointV2(endpointAddr),
            receiveMessageLibAddr,
            sendMessageLibAddr
        );
        vm.stopBroadcast();

        console2.log("Active Network:", activeNetwork);
        console2.log("DVN deployed at:", address(dvn));
    }
}