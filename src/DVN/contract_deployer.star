def deploy_contract(plan, networks, connections):
    plan.print("Deploying DVN contract")

    deployed_addresses = []
    for net in networks:
        active = net.name

        dst_eids = []
        for conn in connections:
            if conn["from"] == active:
                # Find the target network matching the connection's "to" field
                target_net = None
                for n in networks:
                    if n.name == conn["to"]:
                        target_net = n
                        break
                if target_net != None:
                    dst_eids.append(target_net.eid)
                else:
                    fail("No network found for connection 'to' value: " + conn["to"])

        dst_eids_str = ",".join(dst_eids)

        env_vars = {
            "NETWORK": active,
            "RPC": net.rpc,
            "ENDPOINT": net.endpoint,
            "TRUSTED_RECEIVE_LIB": net.trusted_receive_lib,
            "TRUSTED_SEND_LIB": net.trusted_send_lib,
            "EID": net.eid,
            "PRIVATE_KEY": net.private_key,
            "DST_EIDS": dst_eids_str,
        }
        # The forge command uses the active network's RPC URL via --fork-url.
        cmd = ("forge script script/Deploy.sol:DeployDVNContract --broadcast --json --skip-simulation --via-ir --fork-url " + net.rpc + " | grep 'contract_address' | jq -r '.contract_address' | tr -d '\n'")
        deployment = plan.run_sh(
            name = "dvn-contract-deployer-" + active,
            description = "Deploying DVN contract to network " + active,
            image = "tiljordan/layerzero-dvn-contract:v1.0.4",
            env_vars = env_vars,
            run = cmd,
        )

        address = deployment.output
        plan.print(address)
        deployed_addresses.append(address)

    return deployed_addresses
