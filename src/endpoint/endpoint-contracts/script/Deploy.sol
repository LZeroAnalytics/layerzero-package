// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../contracts/EndpointV2.sol";

contract DeployEndpoint is Script {
    function run() public {
        // Read the deployer's private key and EID from environment variables
        uint256 deployer = vm.envUint("PRIVATE_KEY");
        uint32 eid = uint32(vm.envUint("EID"));
        
        vm.startBroadcast(deployer);

        // Deploy the EndpointV2 contract
        EndpointV2 endpoint = new EndpointV2(eid, vm.addr(deployer));
        
        vm.stopBroadcast();
        
        console2.log("Deployed EndpointV2 at address:");
        console2.log(address(endpoint));
    }
}
