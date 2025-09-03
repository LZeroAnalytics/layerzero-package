executor_contract_deployer = import_module("./src/executor/contract_deployer.star")
executor_deployer = import_module("./src/executor/executor_launcher.star")
dvn_contract_deployer = import_module("./src/DVN/contract_deployer.star")
dvn_deployer = import_module("./src/DVN/dvn_launcher.star")
address_server = import_module("./src/address-server/server_launcher.star")
redis = import_module("github.com/kurtosis-tech/redis-package/main.star")
input_parser = import_module("./src/package_io/input_parser.star")

def run(plan, args):

    # Check input params
    networks = input_parser.input_parser(plan, args)
    connections = input_parser.compute_connections(args, networks)

    # Deploy DVN contract
    dvn_addresses = dvn_contract_deployer.deploy_contract(plan, networks, connections)

    # Deploy the Executor contract to all networks
    executor_addresses = executor_contract_deployer.deploy_contract(plan, networks, connections)

    # Start a Redis broker for DVN
    dvn_redis_output = redis.run(
        plan,
        service_name = "dvn-redis",
        image = "redis:7",
    )
    dvn_redis_url = "redis://{}:{}".format(dvn_redis_output.hostname, dvn_redis_output.port_number)
    plan.print("DVN Redis running at " + dvn_redis_url)

    # Start a Redis broker for Executor
    executor_redis_output = redis.run(
        plan,
        service_name = "executor-redis",
        image = "redis:7",
    )
    executor_redis_url = "redis://{}:{}".format(executor_redis_output.hostname, executor_redis_output.port_number)
    plan.print("Executor Redis running at " + executor_redis_url)

    # Build a mapping from network name to its deployed addresses
    network_dvn_map = {}
    network_exec_map = {}
    for i, net in enumerate(networks):
        network_dvn_map[net.name] = dvn_addresses[i]
        network_exec_map[net.name] = executor_addresses[i]


    # Add server to serve contract addresses for front-end
    address_server.add_server(plan, dvn_addresses, executor_addresses)

    return struct(
        dvn_addresses = dvn_addresses,
        executor_addresses = executor_addresses,
    )