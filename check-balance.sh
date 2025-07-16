#!/bin/bash

# Quick Contract Balance Checker

echo "💰 Contract Balance Checker"
echo "=========================="

# Load environment variables if .env exists
if [ -f .env ]; then
    source .env
fi

# Check if contract address is provided as argument or in env
CONTRACT_ADDRESS=${1:-$BETTING_GAME_ADDRESS}

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "❌ No contract address provided"
    echo "Usage: $0 <contract_address>"
    echo "Or set BETTING_GAME_ADDRESS in .env file"
    exit 1
fi

echo "📋 Contract Address: $CONTRACT_ADDRESS"
echo ""

# Check Anvil (local)
echo "🔧 Checking Anvil (Local)..."
ANVIL_BALANCE=$(cast balance $CONTRACT_ADDRESS --rpc-url http://127.0.0.1:8545 2>/dev/null)
if [ $? -eq 0 ]; then
    ANVIL_ETH=$(echo $ANVIL_BALANCE | cast --to-unit ether)
    echo "✅ Anvil Balance: $ANVIL_ETH ETH"
else
    echo "❌ Anvil not running or contract not deployed"
fi

# Check Sepolia (if RPC URL is available)
if [ ! -z "$SEPOLIA_RPC_URL" ]; then
    echo ""
    echo "🌐 Checking Sepolia..."
    SEPOLIA_BALANCE=$(cast balance $CONTRACT_ADDRESS --rpc-url $SEPOLIA_RPC_URL 2>/dev/null)
    if [ $? -eq 0 ]; then
        SEPOLIA_ETH=$(echo $SEPOLIA_BALANCE | cast --to-unit ether)
        echo "✅ Sepolia Balance: $SEPOLIA_ETH ETH"
    else
        echo "❌ Sepolia connection failed or contract not deployed"
    fi
else
    echo "⚠️  SEPOLIA_RPC_URL not set in .env"
fi

echo ""
echo "🎯 To fund the contract:"
echo "Anvil: cast send $CONTRACT_ADDRESS --value 1ether --rpc-url http://127.0.0.1:8545"
echo "Sepolia: cast send $CONTRACT_ADDRESS --value 1ether --private-key \$PRIVATE_KEY --rpc-url \$SEPOLIA_RPC_URL"
