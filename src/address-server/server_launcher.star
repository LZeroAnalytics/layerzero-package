def add_server(
        plan,
        dvns,
        executors
):
    plan.add_service(
        name="address-server",
        config=ServiceConfig(
            image="raveenabhasin/layerzero-address-server:1.1.1",
            ports={
                "api": PortSpec(number=3000, transport_protocol="TCP", wait=None),
            },
            env_vars = {
                "DVN_ADDRESSES": ",".join(dvns),
                "EXECUTOR_ADDRESSES": ",".join(executors)
            },
        )
    )