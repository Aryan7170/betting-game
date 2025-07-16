# Sepolia Deployment Guide

## Prerequisites

### 1. Get Sepolia ETH
- Go to [Sepolia Faucet](https://sepoliafaucet.com/) or [Alchemy Sepolia Faucet](https://sepoliafaucet.com/)
- Connect your wallet and request test ETH
- You need at least 0.1 ETH for deployment and VRF subscription

### 2. Set Up Environment Variables

Create a `.env` file in your project root:

```bash
# Private key (without 0x prefix)
PRIVATE_KEY=your_private_key_here

# RPC URL - choose one:
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your_api_key
# OR
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_project_id
# OR use public RPC (slower)
SEPOLIA_RPC_URL=https://rpc.sepolia.org

# Optional: For contract verification
ETHERSCAN_API_KEY=your_etherscan_api_key
```

### 3. Update foundry.toml

Add RPC configuration:

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
optimizer = true
optimizer_runs = 200
via_ir = true
remappings = [
    "@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/",
    "foundry-devops/=lib/foundry-devops/",
]

[rpc_endpoints]
sepolia = "${SEPOLIA_RPC_URL}"
```

## Deployment Steps

### Step 1: Load Environment Variables
```bash
source .env
```

### Step 2: Deploy to Sepolia
```bash
forge script script/Deploy.s.sol:DeployBettingGame --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

### Step 3: Alternative Deployment (if Step 2 fails)
```bash
# Deploy without verification first
forge script script/Deploy.s.sol:DeployBettingGame --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast

# Then verify separately
forge verify-contract <CONTRACT_ADDRESS> src/BettingGame.sol:BettingGame --chain-id 11155111 --etherscan-api-key $ETHERSCAN_API_KEY
```

## Common Issues and Solutions

### Issue 1: "Failed to get EIP-1559 fees"
**Solution**: Add legacy transaction flag
```bash
forge script script/Deploy.s.sol:DeployBettingGame --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast --legacy
```

### Issue 2: "Insufficient funds for gas"
**Solution**: 
- Get more Sepolia ETH from faucet
- Check your wallet balance: `cast balance $YOUR_ADDRESS --rpc-url sepolia`

### Issue 3: "VRF Subscription failed"
**Solution**: The script automatically creates and funds a VRF subscription. Make sure you have enough ETH.

### Issue 4: "Contract verification failed"
**Solution**: 
- Check your Etherscan API key
- Verify manually after deployment
- Use `--verify` flag separately

## Manual Verification Steps

If automatic verification fails:

1. **Get contract address** from deployment output
2. **Verify on Etherscan**:
```bash
forge verify-contract <CONTRACT_ADDRESS> src/BettingGame.sol:BettingGame --chain-id 11155111 --etherscan-api-key $ETHERSCAN_API_KEY --constructor-args $(cast abi-encode "constructor(uint64,address,bytes32,uint32)" <SUBSCRIPTION_ID> <VRF_COORDINATOR> <GAS_LANE> <CALLBACK_GAS_LIMIT>)
```

## Check Deployment Status

### View Transaction
```bash
cast tx <TX_HASH> --rpc-url sepolia
```

### Check Contract
```bash
cast code <CONTRACT_ADDRESS> --rpc-url sepolia
```

### Check Balance
```bash
cast balance <CONTRACT_ADDRESS> --rpc-url sepolia
```

## Testing on Sepolia

1. **Fund contract** with test ETH for payouts
2. **Update frontend** with deployed contract address
3. **Connect MetaMask** to Sepolia network
4. **Test betting** functionality

## RPC Providers

### Alchemy (Recommended)
- Sign up at [alchemy.com](https://alchemy.com)
- Create app for Ethereum Sepolia
- Use provided URL

### Infura
- Sign up at [infura.io](https://infura.io)
- Create project for Ethereum
- Use Sepolia endpoint

### Public RPC (Backup)
- URL: `https://rpc.sepolia.org`
- May be slower and less reliable
