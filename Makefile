# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

CURRENT_IMPL := $(shell jq -r '.lendToAaveMigrator.currentImplementation' utils/addresses.json)

# Build & test
build :; forge build
test  :; forge test -vvv

# Download the current onchain LendToAaveMigrator implementation source from Etherscan.
download :; cast source --chain mainnet -d etherscan ${CURRENT_IMPL}

git-diff :
	@mkdir -p diffs
	@printf '%s\n%s\n%s\n' "\`\`\`diff" "$$(git diff --no-index --diff-algorithm=patience --ignore-space-at-eol ${before} ${after})" "\`\`\`" > diffs/${out}.md

storage-diff :
	@mkdir -p reports diffs
	FOUNDRY_SRC=etherscan/LendToAaveMigrator forge inspect etherscan/LendToAaveMigrator/src/contracts/LendToAaveMigrator.sol:LendToAaveMigrator storage-layout --md --remappings solidity-utils/=etherscan/LendToAaveMigrator/lib/solidity-utils/src/ > reports/LendToAaveMigrator_layout.md
	forge inspect src/LendToAaveMigrator.sol:LendToAaveMigrator storage-layout --md > reports/rescue_LendToAaveMigrator_layout.md
	make git-diff before=reports/LendToAaveMigrator_layout.md after=reports/rescue_LendToAaveMigrator_layout.md out=rescue_LendToAaveMigrator_layout_diff
	make git-diff before=etherscan/LendToAaveMigrator/src/contracts/LendToAaveMigrator.sol after=src/LendToAaveMigrator.sol out=LendToAaveMigrator-diff
