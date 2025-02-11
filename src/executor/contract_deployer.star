def deploy_contract(
        plan
):
    plan.run_sh(
        name="contract-deployer",
        description="Deploying Executor contracts",
        image="tiljordan/layerzero-executor-contract:v1.0.0",
        env_vars = {
            "NETWORKS": "lzero",
            "RPC_LZERO": "http://127.0.0.1:58370",
            "ENDPOINT_LZERO": "0x1a44076050125825900e736c501f859c50fE728c",
            "EID_LZERO": 30101,
            "EXEC_FEE_LZERO": 10000000000000000
        },
        run="whoami"
    )
    # forge script script/Deploy.sol:DeploySimpleExecutor --broadcast --skip-simulation --via-ir