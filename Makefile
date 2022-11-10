-include .env

#export FOUNDRY_ETH_RPC_URL=${BSC_TESTNET}
#  export FOUNDRY_ETHERSCAN_API_KEY=${etherscan-api-key}
#  export PRIVATE_KEY=${private_key}

 update-submodules: 
	@echo Update git submodules
	@git submodule update --init --recursive

deploy-commit:
	@echo Deploying to Testnet
	@forge script script/WKDCommit.s.sol:CommitDeployment --rpc-url FOUNDRY_ETH_RPC_URL --private-key --broadcast --verify --etherscan-api-key -vvvvv