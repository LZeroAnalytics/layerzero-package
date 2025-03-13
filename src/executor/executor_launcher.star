def add_executor(
        plan,
        src_name,
        src_chain_id,
        src_rpc_url,
        src_endpoint,
        src_trusted_send_lib,
        src_executor_addr,
        dst_name,
        dst_chain_id,
        dst_rpc_url,
        dst_endpoint,
        dst_private_key,
        redis_url,
):
    watcher = plan.add_service(
        name = "executor-watcher-{}-{}".format(src_name, dst_name),
        config = ServiceConfig(
            image = "tiljordan/layerzero-executor-watcher:v1.0.1",
            ports = {},
            entrypoint = ["node", "dist/index.js"],
            cmd = [],
            env_vars = {
                "SRC_NAME": src_name,
                "SRC_CHAIN_ID": src_chain_id,
                "SRC_RPC_URL": src_rpc_url,
                "SRC_ENDPOINT": src_endpoint,
                "SRC_TRUSTED_SEND_LIB": src_trusted_send_lib,
                "SRC_EXECUTOR_ADDR": src_executor_addr,
                "DST_NAME": dst_name,
                "DST_CHAIN_ID": dst_chain_id,
                "DST_RPC_URL": dst_rpc_url,
                "DST_ENDPOINT": dst_endpoint,
                "REDIS_URL": redis_url,
            },
        ),
        description = "Adding executor watcher for channel {} -> {}".format(src_name, dst_name)
    )

    committer = plan.add_service(
        name = "committer-{}-{}".format(src_name, dst_name),
        config = ServiceConfig(
            image = "tiljordan/layerzero-committer:v1.0.2",
            ports = {},
            entrypoint = ["node", "dist/index.js"],
            cmd = [],
            env_vars = {
                "DST_NAME": dst_name,
                "DST_CHAIN_ID": dst_chain_id,
                "DST_RPC_URL": dst_rpc_url,
                "DST_PRIVATE_KEY": dst_private_key,
                "REDIS_URL": redis_url,
            },
        ),
        description = "Adding committer for channel {} -> {}".format(src_name, dst_name)
    )

    executor = plan.add_service(
        name = "executor-{}-{}".format(src_name, dst_name),
        config = ServiceConfig(
            image = "tiljordan/layerzero-executor:v1.0.2",
            ports = {},
            entrypoint = ["node", "dist/index.js"],
            cmd = [],
            env_vars = {
                "DST_NAME": dst_name,
                "DST_CHAIN_ID": dst_chain_id,
                "DST_RPC_URL": dst_rpc_url,
                "DST_ENDPOINT": dst_endpoint,
                "DST_PRIVATE_KEY": dst_private_key,
                "REDIS_URL": redis_url,
            },
        ),
        description = "Adding executor for channel {} -> {}".format(src_name, dst_name)
    )

    return watcher, committer, executor