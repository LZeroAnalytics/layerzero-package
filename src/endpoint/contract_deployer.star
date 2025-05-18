def deploy_contract(plan, network):
    """
    Deploy the LayerZero Endpoint contract to a network if it doesn't exist.
    Returns the endpoint address (either existing or newly deployed).
    """
    plan.print(f"Checking if LayerZero Endpoint exists for network {network.name}")
    
    # First check if the endpoint exists by calling a view function
    check_cmd = f"""
    curl -s -X POST -H "Content-Type: application/json" \\
    -d '{{"jsonrpc":"2.0","method":"eth_call","params":[{{"to":"{network.endpoint}","data":"0x06fdde03"}},"latest"],"id":1}}' \\
    {network.rpc} | jq -r '.result' | tr -d '\\n'
    """
    
    check_result = plan.run_sh(
        name = f"endpoint-check-{network.name}",
        description = f"Checking if endpoint exists on network {network.name}",
        image = "badouralix/curl-jq",
        run = check_cmd,
    )
    
    # If the endpoint exists (returns a valid response), use the existing address
    if check_result.exit_code == 0 and check_result.output != "0x" and not check_result.output.startswith("0x08c379a0"):
        plan.print(f"LayerZero Endpoint already exists at {network.endpoint} for network {network.name}")
        return network.endpoint
    
    # If the endpoint doesn't exist, deploy it
    plan.print(f"LayerZero Endpoint not found at {network.endpoint} for network {network.name}. Deploying new endpoint...")
    
    env_vars = {
        "NETWORK": network.name,
        "RPC": network.rpc,
        "PRIVATE_KEY": network.private_key,
        "EID": network.eid,
    }
    
    cmd = ("forge script script/Deploy.sol:DeployEndpoint --broadcast --json --skip-simulation --via-ir --fork-url " + network.rpc + " | grep 'contract_address' | jq -r '.contract_address' | tr -d '\n'")
    
    deployment = plan.run_sh(
        name = f"endpoint-deployer-{network.name}",
        description = f"Deploying LayerZero Endpoint to network {network.name}",
        image = "tiljordan/layerzero-endpoint-contract:v1.0.0",  # This image needs to be created
        env_vars = env_vars,
        run = cmd,
    )
    
    endpoint_address = deployment.output
    plan.print(f"Deployed LayerZero Endpoint at {endpoint_address} for network {network.name}")
    
    return endpoint_address
