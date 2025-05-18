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

    if "connections" not in input_args:
        fail("Input must contain 'connections' field.")

    connections = input_args["connections"]
    if len(connections) < 1:
        fail("At least one connection must be specified.")

    for connection in connections:
        # Check that connection has 'to' and 'from' fields.
        if "to" not in connection:
            fail("Connection is missing 'to' field.")
        if "from" not in connection:
            fail("Connection is missing 'from' field.")
        if "exec_fee" not in connection:
            fail ("Connection is missing 'exec_fee' field")
        if "dvn_fee" not in connection:
            fail("Connection is missing 'dvn_fee' field")

        # Validate that the 'to' and 'from' values correspond to a valid network name.
        valid_network_names = [network["name"] for network in input_args["networks"]]
        if connection["to"] not in valid_network_names:
            fail("Connection 'to' field value '%s' does not match any network name." % connection["to"])
        if connection["from"] not in valid_network_names:
            fail("Connection 'from' field value '%s' does not match any network name." % connection["from"])

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
        else:
            # For networks without a type, ensure they have the optional fields
            # If not provided, we'll use placeholder values that will be replaced with deployed contracts
            for field in OPTIONAL_FIELDS:
                if field not in network:
                    if field == "endpoint":
                        network[field] = "0x0000000000000000000000000000000000000000"
                    elif field == "trusted_send_lib":
                        network[field] = "0x0000000000000000000000000000000000000000"
                    elif field == "trusted_receive_lib":
                        network[field] = "0x0000000000000000000000000000000000000000"
                    elif field == "eid" and "chain_id" in network:
                        # Generate a default EID based on chain ID if not provided
                        network[field] = str(30000 + int(network["chain_id"]) % 1000)
                    elif field == "chain_id" and "eid" in network:
                        # Generate a default chain ID based on EID if not provided
                        network[field] = str(int(network["eid"]) % 100000)
                    else:
                        fail("Network %d is missing required field '%s' and no default could be generated." % (idx, field))

        # Validate RPC connectivity and chain id
        rpc_url = network["rpc"]
        expected_chain_id = network["chain_id"]

        command = "curl -s -X POST -H \"Content-Type: application/json\" -d '{\"jsonrpc\":\"2.0\",\"method\":\"eth_chainId\",\"params\":[],\"id\":1}' %s | jq -r '.result' | tr -d '\\n' | xargs -r printf '%%d'" % rpc_url

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
            target_value = expected_chain_id,
            description = "Verifying chain id for network %s" % network["name"]
        )

        plan.print("RPC verification passed for network '%s' (chain id: %s)" % (network["name"], result.output))

        parsed_networks.append(struct(
            name = network["name"],
            chain_id = network["chain_id"],
            rpc = network["rpc"],
            endpoint = network["endpoint"],
            trusted_send_lib = network["trusted_send_lib"],
            trusted_receive_lib = network["trusted_receive_lib"],
            eid = network["eid"],
            private_key = network["private_key"]
        ))

    return parsed_networks
