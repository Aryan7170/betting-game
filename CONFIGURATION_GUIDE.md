# Configuration Guide

This document explains how to configure the BettingGame deployment and interaction scripts.

## Environment Variables

### Required for Testnets/Mainnet
- `PRIVATE_KEY`: Your wallet private key (required for all networks except Anvil)
- `VRF_SUBSCRIPTION_ID`: Chainlink VRF subscription ID (required for testnets/mainnet)

### Optional Configuration
- `VRF_CALLBACK_GAS_LIMIT`: Callback gas limit (default: 300000)
- `INITIAL_FUNDING`: Contract funding amount in wei (optional, local testing uses 5 ETH by default)

### Testing Configuration
- `TEST_COIN_BET_AMOUNT`: Coin bet amount in wei (default: 0.01 ETH)
- `TEST_COIN_PREDICTION`: Coin prediction (0 for heads, 1 for tails, default: 0)
- `TEST_DICE_BET_AMOUNT`: Dice bet amount in wei (default: 0.01 ETH)
- `TEST_DICE_PREDICTION`: Dice prediction (1-6, default: 4)

### Interaction
- `BETTING_GAME_ADDRESS`: Deployed contract address (required for interactions)

## Deployment Options

### 1. Environment-based Deployment (Recommended)
```bash
# Set environment variables
export VRF_SUBSCRIPTION_ID=123
export INITIAL_FUNDING=1000000000000000000  # 1 ETH

# Deploy
make deploy-sepolia
```

### 2. Parameter-based Deployment
```bash
# Deploy with explicit parameters
SUBSCRIPTION_ID=123 FUNDING_AMOUNT=1000000000000000000 make deploy-with-params

# Or directly with forge
forge script script/Deploy.s.sol --sig "run(uint64,uint256)" 123 1000000000000000000 --rpc-url $RPC_URL --broadcast
```

### 3. Local Testing (Default behavior)
```bash
# Start Anvil
make anvil

# Deploy locally (automatically funded with 5 ETH)
make deploy-local
```

## Configuration Behavior

### Hardcoded Values
- **Local Testing Only**: Default test values in `Interact.s.sol` (0.01 ETH bets, specific predictions)
- **Network Defaults**: Gas lanes and VRF coordinators for each network

### Configurable Values
- **Subscription ID**: Must be set via `VRF_SUBSCRIPTION_ID` for testnets/mainnet
- **Callback Gas Limit**: Can be customized via `VRF_CALLBACK_GAS_LIMIT`
- **Contract Funding**: Can be set via `INITIAL_FUNDING` for deployment
- **Test Parameters**: Can be customized via `TEST_*` variables

### Default Behavior
- **Local**: Uses hardcoded subscription ID (1) and mock VRF
- **Testnets/Mainnet**: Requires `VRF_SUBSCRIPTION_ID` or defaults to 1 (with warning)
- **Funding**: No funding by default (except 5 ETH for local testing)

## Examples

### Deploy to Sepolia with Custom Configuration
```bash
export VRF_SUBSCRIPTION_ID=456
export VRF_CALLBACK_GAS_LIMIT=500000
export INITIAL_FUNDING=2000000000000000000  # 2 ETH
make deploy-sepolia
```

### Test with Custom Betting Parameters
```bash
export TEST_COIN_BET_AMOUNT=50000000000000000  # 0.05 ETH
export TEST_COIN_PREDICTION=1  # Tails
export TEST_DICE_BET_AMOUNT=20000000000000000  # 0.02 ETH
export TEST_DICE_PREDICTION=6  # Roll a 6
make interact-local
```

### Check Environment Configuration
```bash
make check-env
```

This will validate that all necessary environment variables are set and provide helpful feedback about configuration status.
