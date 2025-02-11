def deploy_contract(plan, networks):
    plan.print("Deploying Executor contract with computed fee arrays")

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
            "RPC_" + active_upper: net["rpc"],
            "ENDPOINT_" + active_upper: net["endpoint"],
            "EID_" + active_upper: net["eid"],
            "EXEC_FEE_" + active_upper: net["exec_fee"],
            "PRIVATE_KEY": net["private_key"],
            "DST_EIDS": dst_eids_str,
            "FEES": fees_str,
        }
        # The forge command uses the active network's RPC URL via --fork-url.
        cmd = ("forge script script/Deploy.sol:DeploySimpleExecutor "
               "--broadcast --skip-simulation --via-ir --fork-url " + net["rpc"])
        plan.run_sh(
            name = "contract-deployer-" + active,
            description = "Deploying Executor contract to network " + active,
            image = "tiljordan/layerzero-executor-contract:v1.0.0",
            env_vars = env_vars,
            run = cmd,
        )