executor_contract_deployer = import_module("./src/executor/contract_deployer.star")
def run(plan):
    executor_contract_deployer.deploy_contract(plan)