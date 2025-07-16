# Makefile for BettingGame Foundry Project

# Load environment variables from .env file
-include .env
export

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
	@echo "  make deploy-sepolia   Deploy to Sepolia testnet (uses environment variables)"
	@echo "  make deploy-mainnet   Deploy to Ethereum mainnet (uses environment variables)"
	@echo "  make check-env        Check environment variables"
	@echo ""
	@echo "Required Environment Variables:"
	@echo "  PRIVATE_KEY           Private key for deployment"
	@echo "  ACCOUNT_ADDRESS       Account address for deployment"
	@echo "  VRF_SUBSCRIPTION_ID   Chainlink VRF subscription ID"
	@echo "  VRF_CALLBACK_GAS_LIMIT Callback gas limit (default: 300000)"
	@echo "  SEPOLIA_VRF_COORDINATOR Sepolia VRF coordinator address"
	@echo "  SEPOLIA_VRF_KEYHASH   Sepolia VRF key hash"
	@echo "  MAINNET_VRF_COORDINATOR Mainnet VRF coordinator address"
	@echo "  MAINNET_VRF_KEYHASH   Mainnet VRF key hash"
	@echo "  ALCHEMY_API_KEY       Alchemy API key for RPC"
	@echo "  ETHERSCAN_API_KEY     Etherscan API key for verification"
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
	forge script script/Deploy.s.sol --rpc-url $(ANVIL_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast

.PHONY: deploy-sepolia
deploy-sepolia:
	@echo "Deploying to Sepolia testnet using environment variables..."
	forge script script/Deploy.s.sol --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY)

.PHONY: deploy-mainnet
deploy-mainnet:
	@echo "Deploying to Ethereum mainnet using environment variables..."
	@echo "WARNING: This will deploy to MAINNET! Are you sure? (Press Enter to continue, Ctrl+C to cancel)"
	@read
	forge script script/Deploy.s.sol --rpc-url $(MAINNET_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY)

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
	@if [ -z "$(ACCOUNT_ADDRESS)" ]; then echo "❌ ACCOUNT_ADDRESS not set"; else echo "✅ ACCOUNT_ADDRESS is set"; fi
	@if [ -z "$(VRF_SUBSCRIPTION_ID)" ]; then echo "❌ VRF_SUBSCRIPTION_ID not set"; else echo "✅ VRF_SUBSCRIPTION_ID is set"; fi
	@if [ -z "$(VRF_CALLBACK_GAS_LIMIT)" ]; then echo "❌ VRF_CALLBACK_GAS_LIMIT not set"; else echo "✅ VRF_CALLBACK_GAS_LIMIT is set"; fi
	@if [ -z "$(SEPOLIA_VRF_COORDINATOR)" ]; then echo "❌ SEPOLIA_VRF_COORDINATOR not set"; else echo "✅ SEPOLIA_VRF_COORDINATOR is set"; fi
	@if [ -z "$(SEPOLIA_VRF_KEYHASH)" ]; then echo "❌ SEPOLIA_VRF_KEYHASH not set"; else echo "✅ SEPOLIA_VRF_KEYHASH is set"; fi
	@if [ -z "$(MAINNET_VRF_COORDINATOR)" ]; then echo "❌ MAINNET_VRF_COORDINATOR not set"; else echo "✅ MAINNET_VRF_COORDINATOR is set"; fi
	@if [ -z "$(MAINNET_VRF_KEYHASH)" ]; then echo "❌ MAINNET_VRF_KEYHASH not set"; else echo "✅ MAINNET_VRF_KEYHASH is set"; fi
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
