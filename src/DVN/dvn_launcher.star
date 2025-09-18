def add_dvn(
        plan,
        network_a,
        network_b,
        network_dvn_map,
        redis_url,
):
    """
    Creates DVN services for a network pair.
    """
    
    # Create a deterministic service name (alphabetically sorted to avoid duplicates)
    networks_sorted = sorted([network_a.name, network_b.name])
    service_name_base = "{}-{}".format(networks_sorted[0], networks_sorted[1])
    
    # DVN Watcher - monitors both networks for DVN events
    watcher = plan.add_service(
        name = "dvn-watcher-{}".format(service_name_base),
        config = ServiceConfig(
            image = "tiljordan/layerzero-dvn-watcher:v1.0.2",
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
                
                # Network B configuration
                "NETWORK_B_NAME": network_b.name,
                "NETWORK_B_CHAIN_ID": str(network_b.chain_id),
                "NETWORK_B_RPC_URL": network_b.rpc,
                "NETWORK_B_ENDPOINT": network_b.endpoint,
                "NETWORK_B_TRUSTED_SEND_LIB": network_b.trusted_send_lib,
                
                "REDIS_URL": redis_url,
            },
        ),
        description = "Adding DVN watcher for networks {} <-> {}".format(network_a.name, network_b.name)
    )

    # DVN Verifier - verifies for both networks
    verifier = plan.add_service(
        name = "dvn-verifier-{}".format(service_name_base),
        config = ServiceConfig(
            image = "tiljordan/layerzero-verifier:v1.0.2",
            ports = {},
            entrypoint = ["node", "dist/index.js"],
            cmd = [],
            env_vars = {
                # Network A configuration
                "NETWORK_A_NAME": network_a.name,
                "NETWORK_A_CHAIN_ID": str(network_a.chain_id),
                "NETWORK_A_RPC_URL": network_a.rpc,
                "NETWORK_A_TRUSTED_RECEIVE_LIB": network_a.trusted_receive_lib,
                "NETWORK_A_DVN_ADDRESSES": ",".join(network_dvn_map[network_a.name]),
                "NETWORK_A_DVN_NAMES": ",".join(["DVN-{}".format(i+1) for i in range(len(network_dvn_map[network_a.name]))]),
                "NETWORK_A_DVN_PRIVATE_KEYS": ",".join([network_a.private_key for _ in network_dvn_map[network_a.name]]),
                
                # Network B configuration
                "NETWORK_B_NAME": network_b.name,
                "NETWORK_B_CHAIN_ID": str(network_b.chain_id),
                "NETWORK_B_RPC_URL": network_b.rpc,
                "NETWORK_B_TRUSTED_RECEIVE_LIB": network_b.trusted_receive_lib,
                "NETWORK_B_DVN_ADDRESSES": ",".join(network_dvn_map[network_b.name]),
                "NETWORK_B_DVN_NAMES": ",".join(["DVN-{}".format(i+1) for i in range(len(network_dvn_map[network_b.name]))]),
                "NETWORK_B_DVN_PRIVATE_KEYS": ",".join([network_b.private_key for _ in network_dvn_map[network_b.name]]),
                
                "USE_ALL_DVNS": "true",
                "REDIS_URL": redis_url,
            },
        ),
        description = "Adding DVN verifier for networks {} <-> {}".format(network_a.name, network_b.name),
    )
    
    return watcher, verifier
