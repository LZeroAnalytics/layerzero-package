def deploy_contract(plan, network):
    """
    Deploy the LayerZero Endpoint contract to a network if it doesn't exist.
    Returns the endpoint address (either existing or newly deployed).
    """
    plan.print("Checking if LayerZero Endpoint exists for network %s" % network.name)
    
    # First check if the endpoint exists by calling a view function
    check_cmd = """
    curl -s -X POST -H "Content-Type: application/json" \\
    -d '{"jsonrpc":"2.0","method":"eth_call","params":[{"to":"%s","data":"0x06fdde03"},"latest"],"id":1}' \\
    %s | jq -r '.result' | tr -d '\\n'
    """ % (network.endpoint, network.rpc)
    
    check_result = plan.run_sh(
        name = "endpoint-check-%s" % network.name,
        description = "Checking if endpoint exists on network %s" % network.name,
        image = "badouralix/curl-jq",
        run = check_cmd,
    )
    
    # If the endpoint exists (returns a valid response), use the existing address
    if check_result.output != "0x" and not check_result.output.startswith("0x08c379a0"):
        plan.print("LayerZero Endpoint already exists at %s for network %s" % (network.endpoint, network.name))
        return network.endpoint
    
    # If the endpoint doesn't exist, deploy it
    plan.print("LayerZero Endpoint not found at %s for network %s. Deploying new endpoint..." % (network.endpoint, network.name))
    
    env_vars = {
        "NETWORK": network.name,
        "RPC": network.rpc,
        "PRIVATE_KEY": network.private_key,
        "EID": network.eid,
    }
    
    cmd = ("forge script script/Deploy.sol:DeployEndpoint --broadcast --json --skip-simulation --via-ir --fork-url " + network.rpc + " | grep 'contract_address' | jq -r '.contract_address' | tr -d '\n'")
    
    deployment = plan.run_sh(
        name = "endpoint-deployer-%s" % network.name,
        description = "Deploying LayerZero Endpoint to network %s" % network.name,
        image = "tiljordan/layerzero-endpoint-contract:v1.0.0",  # This image needs to be created
        env_vars = env_vars,
        run = cmd,
    )
    
    endpoint_address = deployment.output
    plan.print("Deployed LayerZero Endpoint at %s for network %s" % (endpoint_address, network.name))
    
    return endpoint_address
