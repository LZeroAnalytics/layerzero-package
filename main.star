# executor_contract_deployer = import_module("./src/executor/contract_deployer.star")
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
    plan.print("Generated %d connections from network mesh" % len(connections))

    # ===== COMMENTED OUT: Original DVN contract deployment flow =====
    # # Deploy DVN contract
    # dvn_addresses = dvn_contract_deployer.deploy_contract(plan, networks, connections)

    # ===== NEW: Extract DVN addresses from networks =====
    network_dvn_map = {}
    all_dvn_addresses = []
    
    for i, network in enumerate(networks):
        if not hasattr(network, 'dvn_addresses') or not network.dvn_addresses:
            fail("Network '%s' must have 'dvnAddresses' field with DVN contract addresses." % network.name)
        
        # Validate all DVN addresses for this network
        validated_dvns = []
        for j, dvn_addr in enumerate(network.dvn_addresses):
            if not dvn_addr.startswith("0x") or len(dvn_addr) != 42:
                fail("Invalid DVN address format in network '%s' at index %d: %s" % (network.name, j, dvn_addr))
            validated_dvns.append(dvn_addr)
        
        # Store all DVN addresses for this network
        network_dvn_map[network.name] = validated_dvns
        all_dvn_addresses.extend(validated_dvns)
        
        plan.print("Network '%s' configured with %d DVN addresses: %s" % (network.name, len(validated_dvns), validated_dvns))
    
    plan.print("Total DVN addresses across all networks: %d" % len(all_dvn_addresses))

    # ===== NEW: Extract executor addresses from networks =====
    network_executor_map = {}
    all_executor_addresses = []
    
    for i, network in enumerate(networks):
        if not hasattr(network, 'executor_address') or not network.executor_address:
            fail("Network '%s' must have 'executorAddress' field with executor contract address." % network.name)
        
        # Validate executor address for this network
        executor_addr = network.executor_address
        if not executor_addr.startswith("0x") or len(executor_addr) != 42:
            fail("Invalid executor address format in network '%s': %s" % (network.name, executor_addr))
        
        # Store executor address for this network
        network_executor_map[network.name] = executor_addr
        all_executor_addresses.append(executor_addr)
        
        plan.print("Network '%s' configured with executor address: %s" % (network.name, executor_addr))
    
    plan.print("Total executor addresses across all networks: %d" % len(all_executor_addresses))

    # Deploy the Executor contract to all networks
    # executor_addresses = executor_contract_deployer.deploy_contract(plan, networks, connections)

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

    # Build a mapping from network name to executor addresses
    # network_exec_map = {}
    # for i, net in enumerate(networks):
    #     network_exec_map[net.name] = executor_addresses[i]

    # ===== NEW: Create bidirectional services for unique network pairs =====
    # Instead of creating services for each connection (eth->pol, pol->eth),
    # create one bidirectional service per unique network pair
    
    network_pairs_processed = []
    
    for conn in connections:
        # Find source and destination networks
        src = None
        dst = None
        for net in networks:
            if net.name == conn["from"]:
                src = net
            if net.name == conn["to"]:
                dst = net

        # Create a deterministic pair identifier (alphabetically sorted)
        pair_names = sorted([src.name, dst.name])
        pair_key = "{}-{}".format(pair_names[0], pair_names[1])
        
        # Skip if we've already processed this network pair
        if pair_key in network_pairs_processed:
            continue
            
        network_pairs_processed.append(pair_key)
        
        plan.print("Creating bidirectional services for network pair: {} <-> {}".format(src.name, dst.name))

        # Create DVN services
        dvn_deployer.add_dvn(
            plan,
            network_a = src,
            network_b = dst,
            network_dvn_map = network_dvn_map,
            redis_url = dvn_redis_url,
        )

        # Create executor services
        executor_deployer.add_executor(
            plan,
            network_a = src,
            network_b = dst,
            network_executor_map = network_executor_map,
            redis_url = executor_redis_url,
        )

    plan.print("Created bidirectional services for %d network pairs" % len(network_pairs_processed))

    # Add server to serve contract addresses for front-end
    address_server.add_server(plan, all_dvn_addresses, all_executor_addresses)

    return struct(
        network_dvn_map = network_dvn_map,
        all_dvn_addresses = all_dvn_addresses,
        network_executor_map = network_executor_map,
        all_executor_addresses = all_executor_addresses,
        network_pairs_count = len(network_pairs_processed),
    )