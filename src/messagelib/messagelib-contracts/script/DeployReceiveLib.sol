// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../uln/uln302/ReceiveUln302.sol";

interface IEndpoint {
    function registerLibrary(address _lib) external;
}

contract DeployMessageLib is Script {
    function run() public {
        // Read the deployer's private key and the endpoint address from environment variables.
        uint256 deployer = vm.envUint("PRIVATE_KEY");
        address endpointAddr = vm.envAddress("ENDPOINT");

        vm.startBroadcast(deployer);

        // Deploy the ReceiveUln302 contract, passing in the endpoint address.
        ReceiveUln302 receiveLib = new ReceiveUln302(endpointAddr);

        // Call registerLibrary on the endpoint to register the newly deployed library.
        IEndpoint(endpointAddr).registerLibrary(address(receiveLib));

        vm.stopBroadcast();
    }
}
