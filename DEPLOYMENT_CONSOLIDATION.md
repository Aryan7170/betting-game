# Deployment Consolidation Summary

## Problem
Previously, there were two separate deployment scripts:
- `Deploy.s.sol` - Environment variable-based deployment
- `DeployWithParams.s.sol` - Parameter-based deployment

This created redundancy and maintenance overhead.

## Solution
Consolidated into a single `Deploy.s.sol` script that supports both approaches:

### 1. Environment Variable Deployment (Default)
```solidity
function run() external {
    _deploy(0, 0); // Uses environment variables
}
```

**Usage:**
```bash
export VRF_SUBSCRIPTION_ID=123
export INITIAL_FUNDING=1000000000000000000
make deploy-sepolia
```

### 2. Parameter-based Deployment
```solidity
function run(uint64 subscriptionId, uint256 fundingAmount) external {
    _deploy(subscriptionId, fundingAmount); // Uses provided parameters
}
```

**Usage:**
```bash
SUBSCRIPTION_ID=123 FUNDING_AMOUNT=1000000000000000000 make deploy-with-params
```

## Key Features

### Unified Logic
- Single `_deploy()` internal function handles both approaches
- Parameter overrides take precedence over environment variables
- Consistent validation and logging

### Smart Parameter Handling
- `subscriptionId = 0` → Use environment variable `VRF_SUBSCRIPTION_ID`
- `subscriptionId != 0` → Use provided parameter (overrides environment)
- `fundingAmount = 0` → Use environment variable `INITIAL_FUNDING`
- `fundingAmount != 0` → Use provided parameter (overrides environment)

### Clear Logging
- Shows which values are from parameters vs environment variables
- Example: "Using subscription ID from parameter: 456"
- Example: "Contract will be funded with 2000000000000000000 wei (from parameter)"

## Benefits

1. **Reduced Duplication**: Single script eliminates maintenance overhead
2. **Flexible Usage**: Supports both environment and parameter approaches
3. **Clear Precedence**: Parameters override environment variables
4. **Better UX**: Clear logging shows which values are being used from where
5. **Backward Compatibility**: All existing usage patterns continue to work

## Migration Impact

- ✅ **No Breaking Changes**: All existing commands work the same
- ✅ **Same Makefile Targets**: `make deploy`, `make deploy-with-params` unchanged
- ✅ **Same Environment Variables**: All existing env vars work as before
- ✅ **Enhanced Flexibility**: Now supports both approaches in one script

## Result

From 2 deployment scripts → 1 consolidated script with enhanced functionality.
