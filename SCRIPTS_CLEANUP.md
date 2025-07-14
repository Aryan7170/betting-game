# Scripts Directory - Clean & Organized

This directory contains **3 essential scripts** for the betting game project, replacing the previous 8 redundant files.

## 📁 Current Scripts Structure

```
script/
├── Deploy.s.sol        # ✅ Unified deployment for all networks
├── HelperConfig.s.sol  # ✅ Network configuration management
└── Interact.s.sol      # ✅ Contract interaction script
```

## 🗑️ Removed Redundant Files

The following files have been **removed** as they were redundant:

- ❌ `DeployBettingGame.s.sol.deprecated` - Replaced by `Deploy.s.sol`
- ❌ `DeployOnAnvil.s.sol.deprecated` - Replaced by `Deploy.s.sol`
- ❌ `DeployBettingGameMultiChain.s.sol.deprecated` - Replaced by `Deploy.s.sol`
- ❌ `InteractBettingGame.s.sol` - Merged into `Interact.s.sol`
- ❌ `LocalTesting.s.sol` - Functionality covered by `Deploy.s.sol` + `Interact.s.sol`

## 📄 Script Details

### 1. **Deploy.s.sol**
- **Purpose**: Unified deployment for all networks
- **Features**:
  - Auto-detects network (Anvil, Sepolia, Mainnet, Polygon, Arbitrum)
  - Deploys MockVRF for local testing
  - Provides deployment information and next steps
  - Handles environment variables gracefully

### 2. **HelperConfig.s.sol**
- **Purpose**: Network configuration management
- **Features**:
  - Supports 5 networks with pre-configured settings
  - Handles VRF coordinator addresses, gas lanes, subscription IDs
  - Provides environment variable fallbacks
  - Validates configurations

### 3. **Interact.s.sol**
- **Purpose**: Contract interaction and testing
- **Features**:
  - Places example coin and dice bets
  - Displays contract state and player bets
  - Provides local testing instructions
  - Works with all networks via HelperConfig

## 🚀 Usage Examples

### Deploy to Local Network
```bash
make deploy-local
```

### Deploy to Sepolia
```bash
make deploy-sepolia
```

### Interact with Contract
```bash
BETTING_GAME_ADDRESS=0x... make interact-local
```

### Manual Commands
```bash
# Deploy
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --broadcast

# Interact
BETTING_GAME_ADDRESS=0x... forge script script/Interact.s.sol --rpc-url <RPC_URL> --broadcast
```

## 📊 Before vs After

| Before | After |
|--------|-------|
| 8 script files | 3 script files |
| Duplicate functionality | Unified & streamlined |
| Hard-coded network configs | Dynamic configuration |
| Separate scripts per network | Single deployment script |
| Complex maintenance | Simple & maintainable |

## ✅ Benefits of Cleanup

1. **Simplified Maintenance**: Only 3 files to maintain instead of 8
2. **No Duplication**: Each script has a single responsibility
3. **Better Organization**: Clear separation of concerns
4. **Easier Onboarding**: New developers can quickly understand the structure
5. **Consistent Behavior**: All scripts use the same HelperConfig
6. **Reduced Errors**: Less chance of inconsistencies between scripts

## 🔧 Testing Status

All scripts have been tested and verified:
- ✅ **Deploy.s.sol** - Successfully deploys on Anvil with MockVRF
- ✅ **HelperConfig.s.sol** - Properly detects networks and provides configurations
- ✅ **Interact.s.sol** - Successfully interacts with deployed contracts
- ✅ **All Tests** - 21/21 tests passing
- ✅ **Makefile** - All commands working correctly

## 📝 Next Steps

The scripts directory is now clean and organized. Future enhancements might include:
- Adding more networks to HelperConfig
- Creating specialized interaction scripts for specific use cases
- Adding deployment verification scripts
- Creating automated testing workflows

---

**Result**: From 8 redundant files to 3 essential, well-organized scripts! 🎉
