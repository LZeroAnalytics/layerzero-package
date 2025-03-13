def add_dvn(
        plan,
        src_name,
        src_chain_id,
        src_rpc_url,
        src_endpoint,
        src_trusted_send_lib,
        src_dvn_addr,
        dst_name,
        dst_chain_id,
        dst_rpc_url,
        dst_endpoint,
        dst_trusted_receive_lib,
        dst_dvn_addr,
        dst_private_key,
        redis_url,
):
    watcher = plan.add_service(
        name = "dvn-watcher-{}-{}".format(src_name, dst_name),
        config = ServiceConfig(
            image = "tiljordan/layerzero-dvn-watcher:v1.0.1",
            ports = {},
            entrypoint = ["node", "dist/index.js"],
            cmd = [],
            env_vars = {
                "SRC_NAME": src_name,
                "SRC_CHAIN_ID": src_chain_id,
                "SRC_RPC_URL": src_rpc_url,
                "SRC_ENDPOINT": src_endpoint,
                "SRC_TRUSTED_SEND_LIB": src_trusted_send_lib,
                "SRC_DVN_ADDR": src_dvn_addr,
                "DST_NAME": dst_name,
                "DST_CHAIN_ID": dst_chain_id,
                "DST_RPC_URL": dst_rpc_url,
                "DST_ENDPOINT": dst_endpoint,
                "REDIS_URL": redis_url,
            },
        ),
        description = "Adding DVN watcher for channel {} -> {}".format(src_name, dst_name)
    )

    verifier = plan.add_service(
        name = "dvn-verifier-{}-{}".format(src_name, dst_name),
        config = ServiceConfig(
            image = "tiljordan/layerzero-verifier:v1.0.1",
            ports = {},
            entrypoint = ["node", "dist/index.js"],
            cmd = [],
            env_vars = {
                "NAME": dst_name,
                "CHAIN_ID": dst_chain_id,
                "RPC_URL": dst_rpc_url,
                "TRUSTED_RECEIVE_LIB": dst_trusted_receive_lib,
                "PRIVATE_KEY": dst_private_key,
                "DVN_ADDR": dst_dvn_addr,
                "REDIS_URL": redis_url,
            },
        ),
        description = "Adding verifier for channel {} -> {}".format(src_name, dst_name),
    )
    return watcher, verifier
