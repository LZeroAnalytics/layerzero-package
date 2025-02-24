// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {ILayerZeroEndpointV2} from "../lib/layerzero-v2/packages/layerzero-v2/evm/protocol/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {LayerZeroDVNContract} from "../src/DVNContract.sol";

contract DeployDVNContract is Script {
    function run() public {
        uint256 deployer = vm.envUint("PRIVATE_KEY");

        // Active network
        string memory activeNetwork = vm.envString("NETWORK");

        // Active network parameters.
        address endpointAddr = vm.envAddress(string("ENDPOINT"));

        vm.startBroadcast(deployer);
        LayerZeroDVNContract dvn = new LayerZeroDVNContract(
            ILayerZeroEndpointV2(endpointAddr)
        );
        vm.stopBroadcast();

        console2.log("Active Network:", activeNetwork);
        console2.log("DVN deployed at:", address(dvn));
    }
}