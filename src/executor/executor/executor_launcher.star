def add_executor(
        plan,
        name,
        rpc_url,
        endpoint,
        endpoint_view,
        trusted_send_lib,
        trusted_receive_lib,
        trusted_receive_lib_view,
        eid,
        executor,
        private_key,
        broker_url
):
    service = plan.add_service(
        name = "{}-executor".format(name),
        config = ServiceConfig(
            image = "tiljordan/layerzero-executor:v1.0.0",
            ports = {},
            entrypoint = ["node", "dist/index.js"],
            cmd = [],
            env_vars = {
                "NAME": name,
                "RPC_URL": rpc_url,
                "ENDPOINT": endpoint,
                "ENDPOINT_VIEW": endpoint_view,
                "TRUSTED_SEND_LIB": trusted_send_lib,
                "TRUSTED_RECEIVE_LIB": trusted_receive_lib,
                "TRUSTED_RECEIVE_LIB_VIEW": trusted_receive_lib_view,
                "EID": eid,
                "EXECUTOR": executor,
                "PRIVATE_KEY": private_key,
                "BROKER_URL": broker_url,
            },
        ),
        description = "LayerZero Executor that subscribes to events from Redis",
    )
    return service
