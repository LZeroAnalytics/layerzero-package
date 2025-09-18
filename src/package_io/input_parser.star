constants = import_module("./constants.star")

REQUIRED_FIELDS = [
    "name",
    "rpc",
    "private_key",
]

OPTIONAL_FIELDS = [
    "endpoint",
    "trusted_send_lib",
    "trusted_receive_lib",
    "eid",
    "chain_id",
]

def input_parser(plan, input_args):
    if "networks" not in input_args:
        fail("Input must contain 'networks' field.")

    networks = input_args["networks"]
    if len(networks) < 2:
        fail("At least two networks must be specified.")

    parsed_networks = []

    for idx, network in enumerate(networks):
        # Validate required fields
        for field in REQUIRED_FIELDS:
            if field not in network:
                fail("Network %d is missing required field '%s'." % (idx, field))

        # Use default values from standard networks
        if "type" in network:
            if network["type"] not in constants.TEMPLATE_NETWORKS:
                fail("Specified network type not supported. Please check the README.md")
            template_network = constants.TEMPLATE_NETWORKS[network["type"]]
            for field in OPTIONAL_FIELDS:
                if field not in network:
                    network[field] = template_network[field]

        # Validate RPC connectivity and chain id
        rpc_url = network["rpc"]
        expected_chain_id = network["chain_id"]

        command = "curl -s -X POST -H \"Content-Type: application/json\" -d '{\"jsonrpc\":\"2.0\",\"method\":\"eth_chainId\",\"params\":[],\"id\":1}' %s | jq -r '.result' | tr -d '\\n' | xargs printf '%%d'" % rpc_url

        result = plan.run_sh(
            run = command,
            name = "curl-job-%d" % idx,
            image = "badouralix/curl-jq",
            wait = "180s",
            description = "Validating RPC connectivity for network %s" % network["name"]
        )

        # Verify that the chain id matches the expected value using plan.verify
        plan.verify(
            value = result.output,
            assertion = "==",
            target_value = str(expected_chain_id),  # Convert to string for comparison
            description = "Verifying chain id for network %s" % network["name"]
        )

        plan.print("RPC verification passed for network '%s' (chain id: %s)" % (network["name"], result.output))

        # Extract DVN addresses if provided
        dvn_addresses = []
        if "dvnAddresses" in network:
            dvn_addresses = network["dvnAddresses"]
        
        # Extract executor address if provided
        executor_address = ""
        if "executorAddress" in network:
            executor_address = network["executorAddress"]
        
        parsed_networks.append(struct(
            name = network["name"],
            chain_id = network["chain_id"],
            rpc = network["rpc"],
            endpoint = network["endpoint"],
            trusted_send_lib = network["trusted_send_lib"],
            trusted_receive_lib = network["trusted_receive_lib"],
            eid = network["eid"],
            private_key = network["private_key"],
            dvn_addresses = dvn_addresses,
            executor_address = executor_address
        ))

    return parsed_networks

def compute_connections(input_args, networks):
    # Create a full mesh using provided defaults
    out = []
    for i, src in enumerate(networks):
        for j, dst in enumerate(networks):
            if i == j:
                continue
            out.append({
                "from": src.name,
                "to": dst.name,
            })
    return out