def deploy_contract(plan, network, endpoint_address):
    """
    Deploy the ULN302 Receive Library contract to a network if it doesn't exist.
    Returns the receive library address (either existing or newly deployed).
    """
    plan.print("Checking if ULN302 Receive Library exists for network %s" % network.name)
    
    # First check if the receive library exists by calling a view function
    check_cmd = "curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"%s\",\"data\":\"0x06fdde03\"},\"latest\"],\"id\":1}' %s | jq -r '.result' | tr -d '\\n'" % (network.trusted_receive_lib, network.rpc)
    
    check_result = plan.run_sh(
        name = "receive-lib-check-%s" % network.name,
        description = "Checking if ULN302 Receive Library exists on network %s" % network.name,
        image = "badouralix/curl-jq",
        run = check_cmd,
    )
    
    # If the receive library exists (returns a valid response), use the existing address
    if check_result.output != "0x" and not check_result.output.startswith("0x08c379a0"):
        plan.print("ULN302 Receive Library already exists at %s for network %s" % (network.trusted_receive_lib, network.name))
        return network.trusted_receive_lib
    
    # If the receive library doesn't exist, deploy it
    plan.print("ULN302 Receive Library not found at %s for network %s. Deploying new receive library..." % (network.trusted_receive_lib, network.name))
    
    env_vars = {
        "NETWORK": network.name,
        "RPC": network.rpc,
        "PRIVATE_KEY": network.private_key,
        "ENDPOINT": endpoint_address,
    }
    
    cmd = ("forge script script/Deploy.sol:DeployMessageLib --broadcast --json --skip-simulation --via-ir --fork-url " + network.rpc + " | grep 'contract_address' | jq -r '.contract_address' | tr -d '\n'")
    
    deployment = plan.run_sh(
        name = "receive-lib-deployer-%s" % network.name,
        description = "Deploying ULN302 Receive Library to network %s" % network.name,
        image = "tiljordan/layerzero-messagelib-contracts:v1.0.0",
        env_vars = env_vars,
        run = cmd,
    )
    
    receive_lib_address = deployment.output
    plan.print("Deployed ULN302 Receive Library at %s for network %s" % (receive_lib_address, network.name))
    
    return receive_lib_address
