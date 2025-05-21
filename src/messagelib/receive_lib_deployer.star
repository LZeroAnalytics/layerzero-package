def deploy_contract(plan, network, endpoint_address):
    """
    Deploy the ULN302 Receive Library contract to a network if it doesn't exist.
    Returns the receive library address (either existing or newly deployed).
    """
    plan.print("Checking if ULN302 Receive Library exists for network %s" % network.name)

    env_vars = {
        "NETWORK": network.name,
        "RPC": network.rpc,
        "PRIVATE_KEY": network.private_key,
        "ENDPOINT": endpoint_address,
    }
    cmd = "(printf '%%s' '{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"%s\",\"data\":\"0x06fdde03\"},\"latest\"],\"id\":1}' | curl -s -H 'Content-Type: application/json' --data-binary @- %s | jq -r '.result // empty' | grep -Eq '^0x$|^0x08c379a0$') && forge script script/DeployReceiveLib.sol:DeployReceiveLib --broadcast --json --skip-simulation --via-ir --fork-url %s | grep 'contract_address' | jq -r '.contract_address' | tr -d '\\n' || echo -n %s" % (network.trusted_receive_lib, network.rpc, network.rpc, network.trusted_receive_lib)

    deployment = plan.run_sh(
        name = "receive-lib-deployer-%s" % network.name,
        description = "Deploying ULN302 Receive Library to network %s" % network.name,
        image = "tiljordan/layerzero-messagelib-contracts:v1.0.0",
        env_vars = env_vars,
        run = cmd,
    )

    receive_lib_address = deployment.output
    plan.print("ULN302 Receive Library address for network %s: %s" % (network.name, receive_lib_address))
    
    return receive_lib_address
