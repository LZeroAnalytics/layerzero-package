def launch_committer(
        plan,
        rpc_url,
        endpoint,
        trusted_send_lib,
        executor,
        eid,
        private_key,
        broker_url
):
    service = plan.add_service(
        name = "layerzero-committer",
        config = ServiceConfig(
            image = "tiljordan/layerzero-committer:v1.0.0",
            ports = {},
            entrypoint = ["node", "dist/index.js"],
            cmd = [],
            env_vars = {
                "RPC_URL": rpc_url,
                "ENDPOINT": endpoint,
                "TRUSTED_SEND_LIB": trusted_send_lib,
                "EXECUTOR": executor,
                "EID": eid,
                "PRIVATE_KEY": private_key,
                "BROKER_URL": broker_url,
            },
        ),
        description = "LayerZero Committer that publishes events to Redis",
    )
    return service