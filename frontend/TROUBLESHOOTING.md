# Fix "Error Getting Stats" Issue

## 🔧 Quick Fix Steps

### Step 1: Deploy Your Contract (if not already deployed)

For **Anvil (local)**:
```bash
# Terminal 1: Start Anvil
anvil

# Terminal 2: Deploy contract
forge script script/Deploy.s.sol:DeployBettingGame --rpc-url http://127.0.0.1:8545 --broadcast

# Look for output like:
# "== Logs =="
# "Deployed BettingGame at: 0x5FbDB2315678afecb367f032d93F642f64180aa3"
```

For **Sepolia**:
```bash
# Deploy to Sepolia
forge script script/Deploy.s.sol:DeployBettingGame --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Step 2: Get Contract Address

Look for the contract address in the deployment output:
```
== Logs ==
Deployed BettingGame at: 0x5FbDB2315678afecb367f032d93F642f64180aa3
```

### Step 3: Update Frontend

1. **Open the frontend** at http://localhost:8080
2. **Enter the contract address** in the configuration section
3. **Click "Update Configuration"**
4. **Connect your wallet**

### Step 4: Fund the Contract (Important!)

```bash
# For Anvil
cast send YOUR_CONTRACT_ADDRESS --value 1ether --rpc-url http://127.0.0.1:8545

# For Sepolia
cast send YOUR_CONTRACT_ADDRESS --value 1ether --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL
```

## 🚨 Common Issues

### Issue 1: "Contract not deployed at this address"
- **Solution**: Deploy the contract first, then use the correct address

### Issue 2: "Network error"
- **Solution**: 
  - For Anvil: Make sure Anvil is running on port 8545
  - For Sepolia: Check your RPC URL and internet connection

### Issue 3: Stats show "0" but no error
- **Solution**: Fund the contract with ETH for payouts

## 🎯 Complete Working Example

```bash
# 1. Start Anvil
anvil

# 2. Deploy contract (in new terminal)
forge script script/Deploy.s.sol:DeployBettingGame --rpc-url http://127.0.0.1:8545 --broadcast

# 3. Copy contract address from output (e.g., 0x5FbDB2315678afecb367f032d93F642f64180aa3)

# 4. Fund contract
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 --value 1ether --rpc-url http://127.0.0.1:8545

# 5. Update frontend:
#    - Enter contract address: 0x5FbDB2315678afecb367f032d93F642f64180aa3
#    - Click "Update Configuration"
#    - Connect MetaMask to localhost:8545
```

## 🔍 Debug Steps

1. **Check browser console** for detailed error messages
2. **Verify contract is deployed**:
   ```bash
   cast code YOUR_CONTRACT_ADDRESS --rpc-url http://127.0.0.1:8545
   ```
3. **Check contract balance**:
   ```bash
   cast balance YOUR_CONTRACT_ADDRESS --rpc-url http://127.0.0.1:8545
   ```

The error should be resolved once you use the correct contract address!
