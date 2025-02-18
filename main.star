executor_contract_deployer = import_module("./src/executor/contract_deployer.star")
committer_deployer = import_module("./src/executor/committer/committer_launcher.star")
executor_deployer = import_module("./src/executor/executor/executor_launcher.star")
redis = import_module("github.com/kurtosis-tech/redis-package/main.star")

def run(plan, args):

    # Deploy the Executor contract to all networks
    executor_contract_deployer.deploy_contract(plan, args["networks"])

    # Start a single Redis broker for committer/executor communication
    redis_output = redis.run(
        plan,
        service_name = "broker-redis",
        image = "redis:7",
    )
    redis_url = "redis://{}:{}".format(redis_output.hostname, redis_output.port_number)
    plan.print("Redis broker running at " + redis_url)

    # For each network, launch a committer and an executor
    for net in args["networks"]:
        name = net["name"]
        rpc_url = net["rpc"]
        endpoint = net["endpoint"]
        endpoint_view = net["endpoint_view"]
        trusted_send_lib = net["trusted_send_lib"]
        trusted_receive_lib = net["trusted_receive_lib"]
        trusted_receive_lib_view = net["trusted_receive_lib_view"]
        eid = net["eid"]  # e.g. "30101"
        executor_addr = net["executor"]
        private_key = net["private_key"]

        plan.print("Launching committer for network " + name)
        committer_deployer.launch_committer(
            plan,
            name = name,
            rpc_url = rpc_url,
            endpoint = endpoint,
            trusted_send_lib = trusted_send_lib,
            executor = executor_addr,
            eid = eid,
            private_key = private_key,
            broker_url = redis_url,
        )

        plan.print("Launching executor for network " + name)
        executor_deployer.add_executor(
            plan,
            name = name,
            rpc_url = rpc_url,
            endpoint = endpoint,
            endpoint_view = endpoint_view,
            trusted_send_lib = trusted_send_lib,
            trusted_receive_lib = trusted_receive_lib,
            trusted_receive_lib_view = trusted_receive_lib_view,
            eid = eid,
            executor = executor_addr,
            private_key = private_key,
            broker_url = redis_url,
        )
