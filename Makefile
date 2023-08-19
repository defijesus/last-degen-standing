# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
build  :; forge build

test   :; forge test -vv
test-contract :; forge test --match-contract ${filter} -vvv

deploy-ledger :; forge script ${contract} --rpc-url ${chain} --broadcast --legacy --ledger --sender ${LEDGER_SENDER} --verify -vvvv
