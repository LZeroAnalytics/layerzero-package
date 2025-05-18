def deploy_contract(plan, network, endpoint_address):
    """
    Deploy the ULN302 Send Library contract to a network if it doesn't exist.
    Returns the send library address (either existing or newly deployed).
    """
    plan.print(f"Checking if ULN302 Send Library exists for network {network.name}")
    
    # First check if the send library exists by calling a view function
    check_cmd = f"""
    curl -s -X POST -H "Content-Type: application/json" \\
    -d '{{"jsonrpc":"2.0","method":"eth_call","params":[{{"to":"{network.trusted_send_lib}","data":"0x06fdde03"}},"latest"],"id":1}}' \\
    {network.rpc} | jq -r '.result' | tr -d '\\n'
    """
    
    check_result = plan.run_sh(
        name = f"send-lib-check-{network.name}",
        description = f"Checking if ULN302 Send Library exists on network {network.name}",
        image = "badouralix/curl-jq",
        run = check_cmd,
    )
    
    # If the send library exists (returns a valid response), use the existing address
    if check_result.exit_code == 0 and check_result.output != "0x" and not check_result.output.startswith("0x08c379a0"):
        plan.print(f"ULN302 Send Library already exists at {network.trusted_send_lib} for network {network.name}")
        return network.trusted_send_lib
    
    # If the send library doesn't exist, deploy it
    plan.print(f"ULN302 Send Library not found at {network.trusted_send_lib} for network {network.name}. Deploying new send library...")
    
    env_vars = {
        "NETWORK": network.name,
        "RPC": network.rpc,
        "PRIVATE_KEY": network.private_key,
        "ENDPOINT": endpoint_address,
    }
    
    cmd = ("forge script script/DeploySendLib.sol:DeploySendLib --broadcast --json --skip-simulation --via-ir --fork-url " + network.rpc + " | grep 'contract_address' | jq -r '.contract_address' | tr -d '\n'")
    
    deployment = plan.run_sh(
        name = f"send-lib-deployer-{network.name}",
        description = f"Deploying ULN302 Send Library to network {network.name}",
        image = "tiljordan/layerzero-messagelib-contracts:v1.0.0",
        env_vars = env_vars,
        run = cmd,
    )
    
    send_lib_address = deployment.output
    plan.print(f"Deployed ULN302 Send Library at {send_lib_address} for network {network.name}")
    
    return send_lib_address
