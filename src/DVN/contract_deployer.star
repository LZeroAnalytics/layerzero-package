def deploy_contract(plan, networks):
    plan.print("Deploying DVN contract")

    deployed_addresses = []
    for net in networks:
        active = net["name"]

        env_vars = {
            "NETWORK": active,
            "RPC": net["rpc"],
            "ENDPOINT": net["endpoint"],
            "PRIVATE_KEY": net["private_key"],
            "TRUSTED_RECEIVE_LIB": net["trusted_receive_lib"],
        }
        # The forge command uses the active network's RPC URL via --fork-url.
        cmd = ("forge script script/Deploy.sol:DeployDVNContract --broadcast --json --skip-simulation --via-ir --fork-url " + net["rpc"] + " | grep 'contract_address' | jq -r '.contract_address' | tr -d '\n'")
        deployment = plan.run_sh(
            name = "dvn-contract-deployer-" + active,
            description = "Deploying DVN contract to network " + active,
            image = "tiljordan/layerzero-dvn-contract:v1.0.0",
            env_vars = env_vars,
            run = cmd,
        )

        address = deployment.output
        plan.print(address)
        deployed_addresses.append(address)

    return deployed_addresses