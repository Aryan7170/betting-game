# Unified Deployment System

This project now uses a unified deployment system that simplifies deployment across multiple networks using the `HelperConfig` contract.

## Overview

The unified deployment system consists of:
- **`HelperConfig.s.sol`**: Network configuration management
- **`Deploy.s.sol`**: Single deployment script for all networks
- **`Interact.s.sol`**: Network-agnostic interaction script
- **`Makefile`**: Easy-to-use commands for common operations

## Key Benefits

✅ **Single Deployment Script**: One script works for all networks
✅ **Auto-Detection**: Automatically detects network and uses appropriate config
✅ **Mock VRF**: Automatically deploys MockVRF for local testing
✅ **Environment Handling**: Gracefully handles missing environment variables
✅ **Network Support**: Pre-configured for 5 networks (Anvil, Sepolia, Mainnet, Polygon, Arbitrum)

## Supported Networks

| Network | Chain ID | VRF Support | Auto-Mock |
|---------|----------|-------------|-----------|
| Anvil Local | 31337 | MockVRF | ✅ |
| Sepolia Testnet | 11155111 | Chainlink VRF | ❌ |
| Ethereum Mainnet | 1 | Chainlink VRF | ❌ |
| Polygon Mainnet | 137 | Chainlink VRF | ❌ |
| Arbitrum One | 42161 | Chainlink VRF | ❌ |

## Usage

### Quick Start

```bash
# Install dependencies
make install

# Deploy locally (auto-detects Anvil)
make deploy-local

# Deploy to Sepolia
make deploy-sepolia

# Deploy to Mainnet
make deploy-mainnet
```

### Manual Deployment

```bash
# Deploy to any network
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --broadcast

# Interact with deployed contract
BETTING_GAME_ADDRESS=<contract_address> forge script script/Interact.s.sol --rpc-url <RPC_URL> --broadcast
```

### Environment Variables

For testnet/mainnet deployment:
```bash
# Required for non-local networks
PRIVATE_KEY=your_private_key_here
ALCHEMY_API_KEY=your_alchemy_api_key  # Optional but recommended
ETHERSCAN_API_KEY=your_etherscan_api_key  # For contract verification
```

For local testing, no environment variables are required.

## HelperConfig Features

### Network Configuration

Each network has its own configuration:
```solidity
struct NetworkConfig {
    uint64 subscriptionId;      // Chainlink VRF subscription ID
    address vrfCoordinator;     // VRF Coordinator address
    bytes32 gasLane;           // Gas lane for VRF requests
    uint32 callbackGasLimit;   // Gas limit for VRF callbacks
    uint256 deployerKey;       // Private key for deployment
    string networkName;        // Human-readable network name
    bool needsMockVRF;         // Whether to deploy MockVRF
}
```

### Key Functions

```solidity
// Get configuration for current network
HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();

// Check if running on local network
bool isLocal = helperConfig.isLocalNetwork();

// Deploy mock VRF (only for local networks)
MockVRFCoordinator mockVRF = helperConfig.deployMockVRF();

// Validate configuration
bool isValid = helperConfig.validateConfig();
```

## Deployment Flow

1. **Initialize HelperConfig**: Automatically detects network and loads appropriate config
2. **Validate Configuration**: Ensures all required parameters are set
3. **Deploy Mock VRF** (if needed): For local networks, deploys MockVRFCoordinator
4. **Deploy BettingGame**: Deploys main contract with network-specific parameters
5. **Fund Contract** (local only): Adds 5 ETH to contract for testing
6. **Display Information**: Shows deployment addresses and next steps

## Adding New Networks

To add a new network, update the `setupNetworkConfigs()` function in `HelperConfig.s.sol`:

```solidity
// Example: Add BSC Mainnet
networkConfigs[56] = NetworkConfig({
    subscriptionId: 1, // Update with your subscription ID
    vrfCoordinator: 0x..., // BSC VRF Coordinator
    gasLane: 0x..., // BSC gas lane
    callbackGasLimit: 300000,
    deployerKey: getPrivateKeyOrDefault(),
    networkName: "BSC Mainnet",
    needsMockVRF: false
});
```

## Testing

The unified system maintains compatibility with all existing tests:

```bash
# Run all tests
make test

# Run specific test types
make test-unit
make test-integration
make test-gas

# Run with verbose output
make test-verbose
```

## Migration from Old System

The old separate deployment scripts (`DeployBettingGame.s.sol`, `DeployOnAnvil.s.sol`) are still present but deprecated. The new unified system provides the same functionality with better maintainability.

### Old vs New

| Old Approach | New Approach |
|-------------|-------------|
| `DeployBettingGame.s.sol` | `Deploy.s.sol` |
| `DeployOnAnvil.s.sol` | `Deploy.s.sol` |
| Hard-coded network configs | `HelperConfig.s.sol` |
| Separate scripts per network | Single script for all networks |

## Troubleshooting

### Common Issues

1. **Environment Variable Not Found**: The system gracefully falls back to Anvil defaults
2. **Invalid Network**: Unknown networks default to Anvil configuration
3. **VRF Subscription**: Update subscription ID in `HelperConfig.s.sol` for testnets/mainnet
4. **Gas Issues**: Adjust `callbackGasLimit` in network configuration

### Debug Mode

For detailed logs during deployment:
```bash
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --broadcast -vvv
```

## Best Practices

1. **Always test locally first**: Use `make deploy-local` before deploying to testnet/mainnet
2. **Fund VRF subscriptions**: Ensure LINK tokens are available for VRF requests
3. **Set appropriate gas limits**: Different networks have different gas requirements
4. **Verify contracts**: Use `--verify` flag for public networks
5. **Keep private keys secure**: Never commit private keys to version control

## Future Enhancements

Potential improvements to the unified system:
- [ ] Support for more networks (Optimism, Avalanche, etc.)
- [ ] Dynamic gas price adjustments
- [ ] Automated VRF subscription management
- [ ] Integration with deployment frameworks
- [ ] Multi-signature deployment support
