def deploy_contract(plan, networks, connections):
    plan.print("Deploying Executor contract with computed fee arrays (Executor)")
    deployed_addresses = []
    for net in networks:
        active = net.name
        dst_eids = []
        fees = []
        for conn in connections:
            if conn["from"] == active:
                target_net = None
                for n in networks:
                    if n.name == conn["to"]:
                        target_net = n
                        break
                if target_net != None:
                    dst_eids.append(target_net.eid)
                    fees.append(conn["exec_fee"])
                else:
                    fail("No network found for connection 'to' value: " + conn["to"])
        dst_eids_str = ",".join(dst_eids)
        fees_str = ",".join(fees)

        env_vars = {
            "NETWORK": active,
            "RPC": net.rpc,
            "ENDPOINT": net.endpoint,
            "EID": net.eid,
            "PRIVATE_KEY": net.private_key,
            "DST_EIDS": dst_eids_str,
            "FEES": fees_str,
            "TRUSTED_SEND_LIB": net.trusted_send_lib,
        }
        cmd = ("forge script script/Deploy.sol:DeploySimpleExecutor --broadcast --json --skip-simulation --via-ir --fork-url " + net.rpc + " | grep 'contract_address' | jq -r '.contract_address' | tr -d '\n'")
        deployment = plan.run_sh(
            name = "executor-contract-deployer-" + active,
            description = "Deploying Executor contract to network " + active,
            image = "tiljordan/layerzero-executor-contract:v1.0.2",
            env_vars = env_vars,
            run = cmd,
        )
        address = deployment.output
        plan.print(address)
        deployed_addresses.append(address)
    return deployed_addresses