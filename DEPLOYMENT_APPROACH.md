# Deployment Configuration Guide

This guide explains how the deployment scripts work after the recent refactoring.

## Overview

The deployment scripts now use a **unified approach** with a single `run()` function that automatically detects the network and uses the appropriate configuration method:

- **Anvil (Chain ID 31337)**: Uses environment variables
- **Other Networks**: Uses parameters passed to the script

## How It Works

The deployment script uses `HelperConfig` to automatically detect the current network and handle configuration accordingly. You don't need to worry about which function to call - the script intelligently chooses the right approach.

## Anvil Deployment (Local Testing)

For local development on Anvil, the deployment automatically uses environment variables:

```bash
# Start Anvil
make anvil

# Deploy using environment variables (optional)
export VRF_CALLBACK_GAS_LIMIT=500000
export INITIAL_FUNDING=1000000000000000000  # 1 ETH in wei
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Deploy to Anvil
make deploy-anvil

# Or deploy directly with forge
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Environment Variables for Anvil:
- `VRF_CALLBACK_GAS_LIMIT`: Gas limit for VRF callback (default: 300000)
- `INITIAL_FUNDING`: Initial funding amount in wei (optional)
- `PRIVATE_KEY`: Private key for deployment (falls back to Anvil default)

## Other Networks Deployment (Sepolia, Mainnet, etc.)

For other networks, the deployment automatically uses parameters passed directly to the script:

```bash
# Deploy to Sepolia
SUBSCRIPTION_ID=123 PRIVATE_KEY=0x123... make deploy-sepolia

# Deploy to Sepolia with all parameters
SUBSCRIPTION_ID=123 PRIVATE_KEY=0x123... CALLBACK_GAS_LIMIT=500000 FUNDING_AMOUNT=1000000000000000000 make deploy-sepolia

# Deploy to Mainnet (with confirmation prompt)
SUBSCRIPTION_ID=123 PRIVATE_KEY=0x123... make deploy-mainnet
```

### Parameters for Other Networks:
- `SUBSCRIPTION_ID`: Chainlink VRF subscription ID (**required**)
- `PRIVATE_KEY`: Private key for deployment (**required**)
- `CALLBACK_GAS_LIMIT`: Gas limit for VRF callback (optional, default: 300000)
- `FUNDING_AMOUNT`: Initial funding amount in wei (optional, default: 0)

## Direct Forge Commands

You can also use forge directly:

```bash
# Anvil (automatically detects and uses environment variables)
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast

# Other networks (automatically detects and requires parameters)
forge script script/Deploy.s.sol --sig "run(uint64,uint256,uint32,uint256)" \
  <subscriptionId> <privateKey> <callbackGasLimit> <fundingAmount> \
  --rpc-url <rpc_url> --broadcast --verify --etherscan-api-key <key>
```

## Key Features

1. **Automatic Detection**: Script automatically detects the network and uses the appropriate configuration method
2. **Single Entry Point**: One `run()` function handles all networks intelligently
3. **Environment Variables for Anvil**: Uses environment variables for local development flexibility
4. **Parameters for Production**: Uses parameters for other networks to avoid configuration mistakes
5. **Validation**: Strict validation ensures required parameters are provided for each network type
6. **Clear Error Messages**: Helpful error messages guide you when required parameters are missing

## Benefits

- **Simplicity**: One deployment script handles all networks
- **Security**: No risk of accidentally using wrong environment variables in production
- **Flexibility**: Easy to script deployments for different networks
- **Clarity**: Clear distinction between local and production deployment methods
- **Validation**: Proper parameter validation prevents deployment errors

## Migration from Old Scripts

The new unified approach makes deployment much simpler:

- **Anvil**: Just call `make deploy-anvil` or `forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast`
- **Other Networks**: Pass parameters directly to the same script

No need to worry about which function to call - the script handles everything automatically!
