executor_contract_deployer = import_module("./src/executor/contract_deployer.star")
executor_deployer = import_module("./src/executor/executor_launcher.star")
dvn_contract_deployer = import_module("./src/DVN/contract_deployer.star")
dvn_deployer = import_module("./src/DVN/dvn_launcher.star")
redis = import_module("github.com/kurtosis-tech/redis-package/main.star")
input_parser = import_module("./src/package_io/input_parser.star")

endpoint_deployer = import_module("./src/endpoint/contract_deployer.star")
send_lib_deployer = import_module("./src/messagelib/send_lib_deployer.star")
receive_lib_deployer = import_module("./src/messagelib/receive_lib_deployer.star")

def run(plan, args):

    # Check input params
    networks = input_parser.input_parser(plan, args)
    connections = args["connections"]
    
    # Check and deploy LayerZero endpoint and ULN302 libraries if needed
    updated_networks = []
    for network in networks:
        # Check and deploy endpoint if needed
        endpoint_address = endpoint_deployer.deploy_contract(plan, network)
        
        # Check and deploy send library if needed
        send_lib_address = send_lib_deployer.deploy_contract(plan, network, endpoint_address)
        
        # Check and deploy receive library if needed
        receive_lib_address = receive_lib_deployer.deploy_contract(plan, network, endpoint_address)
        
        # Create updated network with new addresses
        updated_network = struct(
            name = network.name,
            chain_id = network.chain_id,
            rpc = network.rpc,
            private_key = network.private_key,
            eid = network.eid,
            endpoint = endpoint_address,
            trusted_send_lib = send_lib_address,
            trusted_receive_lib = receive_lib_address
        )
        updated_networks.append(updated_network)
    
    # Replace the networks list with the updated networks
    networks = updated_networks

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

    # For each connection, launch a DVN and executor service between the source and destination networks.
    for conn in connections:
        src = None
        dst = None
        for net in networks:
            if net.name == conn["from"]:
                src = net
            if net.name == conn["to"]:
                dst = net

        dvn_deployer.add_dvn(
            plan,
            src_name = src.name,
            src_chain_id = src.chain_id,
            src_rpc_url = src.rpc,
            src_endpoint = src.endpoint,
            src_trusted_send_lib = src.trusted_send_lib,
            src_dvn_addr = network_dvn_map[src.name],
            dst_name = dst.name,
            dst_chain_id = dst.chain_id,
            dst_rpc_url = dst.rpc,
            dst_endpoint = dst.endpoint,
            dst_trusted_receive_lib = dst.trusted_receive_lib,
            dst_dvn_addr = network_dvn_map[dst.name],
            dst_private_key = dst.private_key,
            redis_url = dvn_redis_url,
        )

        executor_deployer.add_executor(
            plan,
            src_name = src.name,
            src_chain_id = src.chain_id,
            src_rpc_url = src.rpc,
            src_endpoint = src.endpoint,
            src_trusted_send_lib = src.trusted_send_lib,
            src_executor_addr = network_exec_map[src.name],
            dst_name = dst.name,
            dst_chain_id = dst.chain_id,
            dst_rpc_url = dst.rpc,
            dst_endpoint = dst.endpoint,
            dst_private_key = dst.private_key,
            redis_url = executor_redis_url,
        )

    return struct(
        dvn_addresses = dvn_addresses,
        executor_addresses = executor_addresses,
        networks = networks,
    )
