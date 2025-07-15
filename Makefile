# Makefile for BettingGame Foundry Project

# Default to anvil if no network specified
NETWORK ?= anvil

# RPC URLs
ANVIL_RPC_URL = http://127.0.0.1:8545
SEPOLIA_RPC_URL = https://eth-sepolia.g.alchemy.com/v2/$(ALCHEMY_API_KEY)
MAINNET_RPC_URL = https://eth-mainnet.g.alchemy.com/v2/$(ALCHEMY_API_KEY)

# Network configurations
ifeq ($(NETWORK), anvil)
    RPC_URL = $(ANVIL_RPC_URL)
    VERIFY_FLAG = 
else ifeq ($(NETWORK), sepolia)
    RPC_URL = $(SEPOLIA_RPC_URL)
    VERIFY_FLAG = --verify --etherscan-api-key $(ETHERSCAN_API_KEY)
else ifeq ($(NETWORK), mainnet)
    RPC_URL = $(MAINNET_RPC_URL)
    VERIFY_FLAG = --verify --etherscan-api-key $(ETHERSCAN_API_KEY)
endif

# Help
.PHONY: help
help:
	@echo "BettingGame Foundry Project"
	@echo ""
	@echo "Usage:"
	@echo "  make install           Install dependencies"
	@echo "  make build            Build the project"
	@echo "  make test             Run tests"
	@echo "  make test-verbose     Run tests with verbose output"
	@echo "  make clean            Clean build artifacts"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy-anvil     Deploy to local Anvil (uses environment variables)"
	@echo "  make deploy-sepolia   Deploy to Sepolia testnet (requires parameters)"
	@echo "  make deploy-mainnet   Deploy to Ethereum mainnet (requires parameters)"
	@echo "  make check-env        Check environment variables"
	@echo ""
	@echo "Environment Variables (for Anvil only):"
	@echo "  VRF_CALLBACK_GAS_LIMIT Callback gas limit (default: 300000)"
	@echo "  INITIAL_FUNDING       Contract funding amount in wei (optional)"
	@echo "  PRIVATE_KEY           Private key (falls back to Anvil default)"
	@echo ""
	@echo "Parameters (for other networks):"
	@echo "  SUBSCRIPTION_ID       Chainlink VRF subscription ID (required)"
	@echo "  PRIVATE_KEY           Private key for deployment (required)"
	@echo "  CALLBACK_GAS_LIMIT    Callback gas limit (optional, default: 300000)"
	@echo "  FUNDING_AMOUNT        Contract funding amount in wei (optional)"
	@echo ""
	@echo "Examples:"
	@echo "  # Deploy to Anvil (uses environment variables)"
	@echo "  export INITIAL_FUNDING=1000000000000000000 && make deploy-anvil"
	@echo "  # Deploy to Sepolia (uses parameters)"
	@echo "  SUBSCRIPTION_ID=123 PRIVATE_KEY=0x123... make deploy-sepolia"
	@echo "  # Deploy to Sepolia with all parameters"
	@echo "  SUBSCRIPTION_ID=123 PRIVATE_KEY=0x123... CALLBACK_GAS_LIMIT=500000 FUNDING_AMOUNT=1000000000000000000 make deploy-sepolia"
	@echo ""
	@echo "Local Development:"
	@echo "  make anvil            Start local Anvil node"
	@echo "  make deploy-anvil     Deploy to local Anvil"
	@echo "  make interact-local   Interact with local deployment"
	@echo ""
	@echo "Interaction (requires BETTING_GAME_ADDRESS):"
	@echo "  make interact-coin    Place coin bet (requires AMOUNT, PREDICTION)"
	@echo "  make interact-dice    Place dice bet (requires AMOUNT, PREDICTION)"
	@echo "  make interact-fund    Fund contract (requires AMOUNT in wei)"
	@echo "  make fund-contract    Fund contract with ETH (requires AMOUNT in ether)"
	@echo "  make interact-withdraw Withdraw funds (requires AMOUNT)"
	@echo "  make interact-stats   Get game statistics"
	@echo "  make check-balance    Check contract balance"
	@echo ""
	@echo "Testing:"
	@echo "  make test-unit        Run unit tests"
	@echo "  make test-integration Run integration tests"
	@echo "  make test-gas         Run gas report"
	@echo "  make coverage         Generate coverage report"

# Install dependencies
.PHONY: install
install:
	forge install

# Build
.PHONY: build
build:
	forge build

# Clean
.PHONY: clean
clean:
	forge clean

# Tests
.PHONY: test
test:
	forge test

.PHONY: test-verbose
test-verbose:
	forge test -vvv

.PHONY: test-unit
test-unit:
	forge test --match-contract BettingGameTest

.PHONY: test-integration
test-integration:
	forge test --match-contract BettingGameIntegrationTest

.PHONY: test-gas
test-gas:
	forge test --gas-report

.PHONY: coverage
coverage:
	forge coverage

# Local development
.PHONY: anvil
anvil:
	@echo "Starting Anvil local node..."
	anvil

.PHONY: interact-local
interact-local:
	@echo "Interacting with local deployment..."
	forge script script/Interact.s.sol --rpc-url $(ANVIL_RPC_URL) --broadcast

# Deployment
.PHONY: deploy-anvil
deploy-anvil:
	@echo "Deploying to local Anvil using environment variables..."
	forge script script/Deploy.s.sol --rpc-url $(ANVIL_RPC_URL) --broadcast

.PHONY: deploy-sepolia
deploy-sepolia:
	@echo "Deploying to Sepolia testnet using parameters..."
	@if [ -z "$(SUBSCRIPTION_ID)" ]; then echo "ERROR: Please set SUBSCRIPTION_ID"; exit 1; fi
	@if [ -z "$(PRIVATE_KEY)" ]; then echo "ERROR: Please set PRIVATE_KEY"; exit 1; fi
	@CALLBACK_GAS_LIMIT=$${CALLBACK_GAS_LIMIT:-300000}; \
	FUNDING_AMOUNT=$${FUNDING_AMOUNT:-0}; \
	forge script script/Deploy.s.sol --sig "run(uint64,uint256,uint32,uint256)" $(SUBSCRIPTION_ID) $(PRIVATE_KEY) $$CALLBACK_GAS_LIMIT $$FUNDING_AMOUNT --rpc-url $(SEPOLIA_RPC_URL) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY)

.PHONY: deploy-mainnet
deploy-mainnet:
	@echo "Deploying to Ethereum mainnet using parameters..."
	@echo "WARNING: This will deploy to MAINNET! Are you sure? (Press Enter to continue, Ctrl+C to cancel)"
	@read
	@if [ -z "$(SUBSCRIPTION_ID)" ]; then echo "ERROR: Please set SUBSCRIPTION_ID"; exit 1; fi
	@if [ -z "$(PRIVATE_KEY)" ]; then echo "ERROR: Please set PRIVATE_KEY"; exit 1; fi
	@CALLBACK_GAS_LIMIT=$${CALLBACK_GAS_LIMIT:-300000}; \
	FUNDING_AMOUNT=$${FUNDING_AMOUNT:-0}; \
	forge script script/Deploy.s.sol --sig "run(uint64,uint256,uint32,uint256)" $(SUBSCRIPTION_ID) $(PRIVATE_KEY) $$CALLBACK_GAS_LIMIT $$FUNDING_AMOUNT --rpc-url $(MAINNET_RPC_URL) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY)

# Utility commands
.PHONY: format
format:
	forge fmt

.PHONY: lint
lint:
	forge fmt --check

.PHONY: snapshot
snapshot:
	forge snapshot

.PHONY: doc
doc:
	forge doc

# Environment check
.PHONY: check-env
check-env:
	@echo "Checking environment variables..."
	@if [ -z "$(PRIVATE_KEY)" ]; then echo "❌ PRIVATE_KEY not set"; else echo "✅ PRIVATE_KEY is set"; fi
	@if [ -z "$(ALCHEMY_API_KEY)" ]; then echo "❌ ALCHEMY_API_KEY not set"; else echo "✅ ALCHEMY_API_KEY is set"; fi
	@if [ -z "$(ETHERSCAN_API_KEY)" ]; then echo "❌ ETHERSCAN_API_KEY not set"; else echo "✅ ETHERSCAN_API_KEY is set"; fi
	@if [ -z "$(VRF_SUBSCRIPTION_ID)" ]; then echo "⚠️  VRF_SUBSCRIPTION_ID not set (will use default)"; else echo "✅ VRF_SUBSCRIPTION_ID is set"; fi
	@if [ -z "$(VRF_CALLBACK_GAS_LIMIT)" ]; then echo "ℹ️  VRF_CALLBACK_GAS_LIMIT not set (will use default 300000)"; else echo "✅ VRF_CALLBACK_GAS_LIMIT is set"; fi
	@if [ -z "$(INITIAL_FUNDING)" ]; then echo "ℹ️  INITIAL_FUNDING not set (no funding during deployment)"; else echo "✅ INITIAL_FUNDING is set"; fi

# Contract verification (for already deployed contracts)
.PHONY: verify
verify:
	@echo "Verifying contract on $(NETWORK)..."
	forge verify-contract --chain-id $(shell cast chain-id --rpc-url $(RPC_URL)) --constructor-args $(shell cast abi-encode "constructor(uint64,address,bytes32,uint32)" $(SUBSCRIPTION_ID) $(VRF_COORDINATOR) $(GAS_LANE) $(CALLBACK_GAS_LIMIT)) $(CONTRACT_ADDRESS) src/BettingGame.sol:BettingGame --etherscan-api-key $(ETHERSCAN_API_KEY)

# Demo and examples
.PHONY: demo
demo:
	@echo "Running liquidity pool demo..."
	forge test --match-contract LiquidityPoolDemo -vvv

.PHONY: example-bet
example-bet:
	@echo "Example: Place a coin bet (heads = true, 0.01 ETH)"
	cast send $(BETTING_GAME_ADDRESS) "placeCoinBet(bool)" true --value 0.01ether --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY)

.PHONY: example-dice
example-dice:
	@echo "Example: Place a dice bet (number = 3, 0.01 ETH)"
	cast send $(BETTING_GAME_ADDRESS) "placeDiceBet(uint256)" 3 --value 0.01ether --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY)

# Status check
.PHONY: status
status:
	@echo "Contract status:"
	@echo "Balance: $(shell cast balance $(BETTING_GAME_ADDRESS) --rpc-url $(RPC_URL))"
	@echo "Total bets: $(shell cast call $(BETTING_GAME_ADDRESS) "totalBetsPlaced()" --rpc-url $(RPC_URL))"
	@echo "Total payouts: $(shell cast call $(BETTING_GAME_ADDRESS) "totalPayouts()" --rpc-url $(RPC_URL))"
	@echo "Active bets: $(shell cast call $(BETTING_GAME_ADDRESS) "activeBetsCount()" --rpc-url $(RPC_URL))"

# Emergency
.PHONY: emergency-pause
emergency-pause:
	@echo "Emergency pause contract..."
	cast send $(BETTING_GAME_ADDRESS) "pause()" --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY)

.PHONY: emergency-unpause
emergency-unpause:
	@echo "Emergency unpause contract..."
	cast send $(BETTING_GAME_ADDRESS) "unpause()" --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY)

# Enhanced interaction commands
.PHONY: interact-coin
interact-coin:
	@echo "Placing a coin bet..."
	@if [ -z "$(BETTING_GAME_ADDRESS)" ]; then echo "❌ Please set BETTING_GAME_ADDRESS"; exit 1; fi
	@if [ -z "$(AMOUNT)" ]; then echo "❌ Please set AMOUNT (in wei)"; exit 1; fi
	@if [ -z "$(PREDICTION)" ]; then echo "❌ Please set PREDICTION (0 for heads, 1 for tails)"; exit 1; fi
	forge script script/Interact.s.sol:Interact --sig "placeCoinBet(address,uint256,uint256)" $(BETTING_GAME_ADDRESS) $(AMOUNT) $(PREDICTION) --rpc-url $(RPC_URL) --broadcast

.PHONY: interact-dice
interact-dice:
	@echo "Placing a dice bet..."
	@if [ -z "$(BETTING_GAME_ADDRESS)" ]; then echo "❌ Please set BETTING_GAME_ADDRESS"; exit 1; fi
	@if [ -z "$(AMOUNT)" ]; then echo "❌ Please set AMOUNT (in wei)"; exit 1; fi
	@if [ -z "$(PREDICTION)" ]; then echo "❌ Please set PREDICTION (1-6)"; exit 1; fi
	forge script script/Interact.s.sol:Interact --sig "placeDiceBet(address,uint256,uint256)" $(BETTING_GAME_ADDRESS) $(AMOUNT) $(PREDICTION) --rpc-url $(RPC_URL) --broadcast

.PHONY: interact-fund
interact-fund:
	@echo "Funding contract..."
	@if [ -z "$(BETTING_GAME_ADDRESS)" ]; then echo "❌ Please set BETTING_GAME_ADDRESS"; exit 1; fi
	@if [ -z "$(AMOUNT)" ]; then echo "❌ Please set AMOUNT (in wei)"; exit 1; fi
	forge script script/Interact.s.sol:Interact --sig "fundContract(address,uint256)" $(BETTING_GAME_ADDRESS) $(AMOUNT) --rpc-url $(RPC_URL) --broadcast

.PHONY: interact-withdraw
interact-withdraw:
	@echo "Withdrawing funds..."
	@if [ -z "$(BETTING_GAME_ADDRESS)" ]; then echo "❌ Please set BETTING_GAME_ADDRESS"; exit 1; fi
	@if [ -z "$(AMOUNT)" ]; then echo "❌ Please set AMOUNT (in wei)"; exit 1; fi
	forge script script/Interact.s.sol:Interact --sig "withdrawFunds(address,uint256)" $(BETTING_GAME_ADDRESS) $(AMOUNT) --rpc-url $(RPC_URL) --broadcast

.PHONY: interact-stats
interact-stats:
	@echo "Getting game statistics..."
	@if [ -z "$(BETTING_GAME_ADDRESS)" ]; then echo "❌ Please set BETTING_GAME_ADDRESS"; exit 1; fi
	forge script script/Interact.s.sol:Interact --sig "getGameStats(address)" $(BETTING_GAME_ADDRESS) --rpc-url $(RPC_URL)

.PHONY: fund-contract
fund-contract:
	@echo "Funding contract with ETH..."
	@if [ -z "$(BETTING_GAME_ADDRESS)" ]; then echo "❌ Please set BETTING_GAME_ADDRESS"; exit 1; fi
	@if [ -z "$(AMOUNT)" ]; then echo "❌ Please set AMOUNT (in ether, e.g., 1ether)"; exit 1; fi
	cast send $(BETTING_GAME_ADDRESS) --value $(AMOUNT) --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY)

.PHONY: check-balance
check-balance:
	@echo "Checking contract balance..."
	@if [ -z "$(BETTING_GAME_ADDRESS)" ]; then echo "❌ Please set BETTING_GAME_ADDRESS"; exit 1; fi
	@echo "ETH Balance:"
	@cast balance $(BETTING_GAME_ADDRESS) --rpc-url $(RPC_URL)
	@echo "Contract Stats:"
	@cast call $(BETTING_GAME_ADDRESS) "getGameStats()" --rpc-url $(RPC_URL)
