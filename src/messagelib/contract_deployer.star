def deploy_contract(plan, networks):
    plan.print("Deploying message lib receive library")

    deployed_addresses = []
    for net in networks:
        env_vars = {
            "ENDPOINT": net["endpoint"],
            "PRIVATE_KEY": net["private_key"],
        }

        cmd = ("forge script script/Deploy.sol:DeployMessageLib --broadcast --json --skip-simulation --via-ir --fork-url " + net["rpc"] + " | grep 'contract_address' | jq -r '.contract_address' | tr -d '\n'")
        deployment = plan.run_sh(
            name = "contract-deployer-" + net["endpoint"],
            description = "Deploying message lib to network",
            image = "tiljordan/layerzero-messagelib-contracts:v1.0.0",
            env_vars = env_vars,
            run = cmd,
        )

        address = deployment.output
        plan.print(address)
        deployed_addresses.append(address)

    return deployed_addresses