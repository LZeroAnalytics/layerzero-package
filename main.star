executor_contract_deployer = import_module("./src/executor/contract_deployer.star")
committer_deployer = import_module("./src/executor/committer_launcher.star")
executor_deployer = import_module("./src/executor/executor_launcher.star")
messagelib_deployer = import_module("./src/messagelib/contract_deployer.star")
dvn_contract_deployer = import_module("./src/DVN/contract_deployer.star")
dvn_deployer = import_module("./src/DVN/dvn_launcher.star")
address_server = import_module("./src/address-server/server_launcher.star")
redis = import_module("github.com/kurtosis-tech/redis-package/main.star")

def run(plan, args):

    # Deploy MessageLib
    #messagelib_deployer.deploy_contract(plan, args["networks"])

    # Deploy DVN contract
    dvn_addresses = dvn_contract_deployer.deploy_contract(plan, args["networks"])

    # Deploy the Executor contract to all networks
    executor_addresses = executor_contract_deployer.deploy_contract(plan, args["networks"])
    # Start a single Redis broker for committer/executor communication
    redis_output = redis.run(
        plan,
        service_name = "broker-redis",
        image = "redis:7",
    )
    redis_url = "redis://{}:{}".format(redis_output.hostname, redis_output.port_number)
    plan.print("Redis broker running at " + redis_url)

    # For each network, launch a committer, executor, and DVN
    index = 0
    for net in args["networks"]:
        name = net["name"]
        chain_id = net["chain_id"]
        rpc_url = net["rpc"]
        endpoint = net["endpoint"]
        endpoint_view = net["endpoint_view"]
        trusted_send_lib = net["trusted_send_lib"]
        trusted_receive_lib = net["trusted_receive_lib"]
        trusted_receive_lib_view = net["trusted_receive_lib_view"]
        eid = net["eid"]  # e.g. "30101"
        executor_addr = executor_addresses[index]
        dvn_addr = dvn_addresses[index]
        private_key = net["private_key"]

        plan.print("Launching committer for network " + name)
        committer_deployer.launch_committer(
            plan,
            name = name,
            chain_id = chain_id,
            rpc_url = rpc_url,
            endpoint = endpoint,
            trusted_send_lib = trusted_send_lib,
            executor = executor_addr,
            eid = eid,
            private_key = private_key,
            broker_url = redis_url,
        )

        other_names = []
        for other_net in args["networks"]:
            if other_net["name"] != name:
                other_names.append(other_net["name"])
        committer_channels = ",".join(other_names)

        plan.print("Launching executor for network " + name)
        executor_deployer.add_executor(
            plan,
            name = name,
            chain_id = chain_id,
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
            committer_channels = committer_channels,
        )

        plan.print("Launching DVN for network " + name)
        dvn_deployer.add_dvn(
            plan,
            name = name,
            chain_id = chain_id,
            rpc_url = rpc_url,
            endpoint = endpoint,
            endpoint_view = endpoint_view,
            trusted_send_lib = trusted_send_lib,
            trusted_receive_lib = trusted_receive_lib,
            trusted_receive_lib_view = trusted_receive_lib_view,
            eid = eid,
            dvn = dvn_addr,
            private_key = private_key,
            broker_url = redis_url,
            committer_channels = committer_channels,
        )

        index = index + 1

    # Add server to serve addresses
    address_server.add_server(plan, dvn_addresses, executor_addresses)

    return struct(
        dvn_addresses = dvn_addresses,
        executor_addresses = executor_addresses,
    )