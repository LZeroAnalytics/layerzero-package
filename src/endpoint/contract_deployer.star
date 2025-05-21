def deploy_contract(plan, network):
    """
    Deploy the LayerZero Endpoint contract to a network if it doesn't exist.
    Returns the endpoint address (either existing or newly deployed).
    """
    plan.print("Checking if LayerZero Endpoint exists for network %s" % network.name)
    
    env_vars = {
        "NETWORK": network.name,
        "RPC": network.rpc,
        "PRIVATE_KEY": network.private_key,
        "EID": network.eid,
    }

    cmd = "(printf '%%s' '{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"%s\",\"data\":\"0x06fdde03\"},\"latest\"],\"id\":1}' | curl -s -H 'Content-Type: application/json' --data-binary @- %s | jq -r '.result // empty' | grep -Eq '^0x$|^0x08c379a0$') && forge script script/Deploy.sol:DeployEndpoint --broadcast --json --skip-simulation --gas-price 20000000000 --legacy --via-ir --fork-url %s | grep 'contract_address' | jq -r '.contract_address' | tr -d '\\n' | sed 's/null$//' || echo -n %s" % (network.endpoint, network.rpc, network.rpc, network.endpoint)
    deployment = plan.run_sh(
        name = "endpoint-deployer-%s" % network.name,
        description = "If not exists, deploying LayerZero Endpoint to network %s" % network.name,
        image = "tiljordan/layerzero-endpoint-contract:v1.0.0",
        env_vars = env_vars,
        run = cmd,
    )
    
    endpoint_address = deployment.output
    plan.print("LayerZero Endpoint at %s for network %s" % (endpoint_address, network.name))
    
    return endpoint_address
