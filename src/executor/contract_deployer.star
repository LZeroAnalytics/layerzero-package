def deploy_contract(plan, networks):
    plan.print("Deploying Executor contract with computed fee arrays")

    deployed_addresses = []
    for net in networks:
        active = net["name"]
        # Compute destination arrays: for every other network, use its EID and fee.
        dst_eids = []
        fees = []
        for other in networks:
            if other["name"] == active:
                continue
            dst_eids.append(other["eid"])
            fees.append(other["exec_fee"])
        # Convert arrays into comma-separated strings.
        dst_eids_str = ",".join(dst_eids)
        fees_str = ",".join(fees)

        active_upper = active.upper()
        env_vars = {
            "NETWORK": active,
            "RPC": net["rpc"],
            "ENDPOINT": net["endpoint"],
            "EID": net["eid"],
            "EXEC_FEE": net["exec_fee"],
            "PRIVATE_KEY": net["private_key"],
            "DST_EIDS": dst_eids_str,
            "FEES": fees_str,
        }
        # The forge command uses the active network's RPC URL via --fork-url.
        cmd = ("forge script script/Deploy.sol:DeploySimpleExecutor --broadcast --json --skip-simulation --via-ir --fork-url " + net["rpc"] + " | grep 'contract_address' | jq -r '.contract_address' | tr -d '\n'")
        deployment = plan.run_sh(
            name = "contract-deployer-" + active,
            description = "Deploying Executor contract to network " + active,
            image = "tiljordan/layerzero-executor-contract:v1.0.0",
            env_vars = env_vars,
            run = cmd,
        )

        address = deployment.output
        plan.print(address)
        deployed_addresses.append(address)

    return deployed_addresses