def deploy_contract(plan, network, endpoint_address):
    """
    Deploy the ULN302 Receive Library contract to a network if it doesn't exist.
    Returns the receive library address (either existing or newly deployed).
    """
    plan.print(f"Checking if ULN302 Receive Library exists for network {network.name}")
    
    # First check if the receive library exists by calling a view function
    check_cmd = f"""
    curl -s -X POST -H "Content-Type: application/json" \\
    -d '{{"jsonrpc":"2.0","method":"eth_call","params":[{{"to":"{network.trusted_receive_lib}","data":"0x06fdde03"}},"latest"],"id":1}}' \\
    {network.rpc} | jq -r '.result' | tr -d '\\n'
    """
    
    check_result = plan.run_sh(
        name = f"receive-lib-check-{network.name}",
        description = f"Checking if ULN302 Receive Library exists on network {network.name}",
        image = "badouralix/curl-jq",
        run = check_cmd,
    )
    
    # If the receive library exists (returns a valid response), use the existing address
    if check_result.exit_code == 0 and check_result.output != "0x" and not check_result.output.startswith("0x08c379a0"):
        plan.print(f"ULN302 Receive Library already exists at {network.trusted_receive_lib} for network {network.name}")
        return network.trusted_receive_lib
    
    # If the receive library doesn't exist, deploy it
    plan.print(f"ULN302 Receive Library not found at {network.trusted_receive_lib} for network {network.name}. Deploying new receive library...")
    
    env_vars = {
        "NETWORK": network.name,
        "RPC": network.rpc,
        "PRIVATE_KEY": network.private_key,
        "ENDPOINT": endpoint_address,
    }
    
    cmd = ("forge script script/Deploy.sol:DeployMessageLib --broadcast --json --skip-simulation --via-ir --fork-url " + network.rpc + " | grep 'contract_address' | jq -r '.contract_address' | tr -d '\n'")
    
    deployment = plan.run_sh(
        name = f"receive-lib-deployer-{network.name}",
        description = f"Deploying ULN302 Receive Library to network {network.name}",
        image = "tiljordan/layerzero-messagelib-contracts:v1.0.0",
        env_vars = env_vars,
        run = cmd,
    )
    
    receive_lib_address = deployment.output
    plan.print(f"Deployed ULN302 Receive Library at {receive_lib_address} for network {network.name}")
    
    return receive_lib_address
