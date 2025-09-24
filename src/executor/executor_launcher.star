def add_executor(
        plan,
        network_a,
        network_b,
        network_executor_map,
        redis_url,
):
    networks_sorted = sorted([network_a.name, network_b.name])
    service_name_base = "{}-{}".format(networks_sorted[0], networks_sorted[1])
    
    # Executor Watcher - monitors both networks for executor events
    watcher = plan.add_service(
        name = "executor-watcher-{}".format(service_name_base),
        config = ServiceConfig(
            image = "raveenabhasin/layerzero-executor-watcher:1.1.7-final",
            ports = {},
            entrypoint = ["node", "dist/index.js"],
            cmd = [],
            env_vars = {
                # Network A configuration
                "NETWORK_A_NAME": network_a.name,
                "NETWORK_A_CHAIN_ID": str(network_a.chain_id),
                "NETWORK_A_RPC_URL": network_a.rpc,
                "NETWORK_A_ENDPOINT": network_a.endpoint,
                "NETWORK_A_TRUSTED_SEND_LIB": network_a.trusted_send_lib,
                "NETWORK_A_EXECUTOR_ADDR": network_executor_map[network_a.name],
                
                # Network B configuration
                "NETWORK_B_NAME": network_b.name,
                "NETWORK_B_CHAIN_ID": str(network_b.chain_id),
                "NETWORK_B_RPC_URL": network_b.rpc,
                "NETWORK_B_ENDPOINT": network_b.endpoint,
                "NETWORK_B_TRUSTED_SEND_LIB": network_b.trusted_send_lib,
                "NETWORK_B_EXECUTOR_ADDR": network_executor_map[network_b.name],
                
                "REDIS_URL": redis_url,
            },
        ),
        description = "Adding executor watcher for networks {} <-> {}".format(network_a.name, network_b.name)
    )

    # Committer - commits to both networks
    committer = plan.add_service(
        name = "committer-{}".format(service_name_base),
        config = ServiceConfig(
            image = "raveenabhasin/layerzero-committer:1.1.1",
            ports = {},
            entrypoint = ["node", "dist/index.js"],
            cmd = [],
            env_vars = {
                # Network A configuration
                "NETWORK_A_NAME": network_a.name,
                "NETWORK_A_CHAIN_ID": str(network_a.chain_id),
                "NETWORK_A_RPC_URL": network_a.rpc,
                "NETWORK_A_PRIVATE_KEY": network_a.private_key,
                
                # Network B configuration  
                "NETWORK_B_NAME": network_b.name,
                "NETWORK_B_CHAIN_ID": str(network_b.chain_id),
                "NETWORK_B_RPC_URL": network_b.rpc,
                "NETWORK_B_PRIVATE_KEY": network_b.private_key,
                
                "REDIS_URL": redis_url,
            },
        ),
        description = "Adding committer for networks {} <-> {}".format(network_a.name, network_b.name)
    )

    # Executor - executes on both networks
    executor = plan.add_service(
        name = "executor-{}".format(service_name_base),
        config = ServiceConfig(
            image = "raveenabhasin/layerzero-executor:1.1.1",
            ports = {},
            entrypoint = ["node", "dist/index.js"],
            cmd = [],
            env_vars = {
                # Network A configuration
                "NETWORK_A_NAME": network_a.name,
                "NETWORK_A_CHAIN_ID": str(network_a.chain_id),
                "NETWORK_A_RPC_URL": network_a.rpc,
                "NETWORK_A_ENDPOINT": network_a.endpoint,
                "NETWORK_A_PRIVATE_KEY": network_a.private_key,
                
                # Network B configuration
                "NETWORK_B_NAME": network_b.name,
                "NETWORK_B_CHAIN_ID": str(network_b.chain_id),
                "NETWORK_B_RPC_URL": network_b.rpc,
                "NETWORK_B_ENDPOINT": network_b.endpoint,
                "NETWORK_B_PRIVATE_KEY": network_b.private_key,
                
                "REDIS_URL": redis_url,
            },
        ),
        description = "Adding executor for networks {} <-> {}".format(network_a.name, network_b.name)
    )

    return watcher, committer, executor
