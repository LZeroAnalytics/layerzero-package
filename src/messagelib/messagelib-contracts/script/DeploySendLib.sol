// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../contracts/uln/uln302/SendUln302.sol";

interface IEndpoint {
    function registerLibrary(address _lib) external;
}

contract DeploySendLib is Script {
    function run() public {
        // Read the deployer's private key and the endpoint address from environment variables.
        uint256 deployer = vm.envUint("PRIVATE_KEY");
        address endpointAddr = vm.envAddress("ENDPOINT");
        
        vm.startBroadcast(deployer);

        SendUln302 sendLib = new SendUln302(
            endpointAddr,
            3_000_000,
            1 ether
        );
        
        // Call registerLibrary on the endpoint to register the newly deployed library.
        IEndpoint(endpointAddr).registerLibrary(address(sendLib));
        
        vm.stopBroadcast();
        
        console2.log("Deployed SendUln302 at address:");
        console2.log(address(sendLib));
    }
}
