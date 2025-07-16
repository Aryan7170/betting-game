#!/bin/bash

# Environment Setup Script for Sepolia Deployment

echo "🔧 Setting up environment for Sepolia deployment"
echo "==============================================="

# Check if .env already exists
if [ -f .env ]; then
    echo "⚠️  .env file already exists. Backing up to .env.backup"
    cp .env .env.backup
fi

# Create .env file
cat > .env << 'EOF'
# Sepolia Deployment Configuration
# Fill in your values below

# Your wallet private key (without 0x prefix)
# ⚠️ NEVER share this or commit to version control!
PRIVATE_KEY=your_private_key_here

# Sepolia RPC URL - choose one option:

# Option 1: Alchemy (Recommended)
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your_api_key_here

# Option 2: Infura
# SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_project_id_here

# Option 3: Public RPC (may be slower)
# SEPOLIA_RPC_URL=https://rpc.sepolia.org

# Optional: Etherscan API key for contract verification
ETHERSCAN_API_KEY=your_etherscan_api_key_here

# Optional: Other networks
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/your_api_key_here
POLYGON_RPC_URL=https://polygon-mainnet.g.alchemy.com/v2/your_api_key_here
ARBITRUM_RPC_URL=https://arb-mainnet.g.alchemy.com/v2/your_api_key_here
EOF

echo "✅ Created .env file with template"
echo ""
echo "📝 Next steps:"
echo "1. Edit .env file and fill in your values:"
echo "   - PRIVATE_KEY: Your wallet private key"
echo "   - SEPOLIA_RPC_URL: Get from Alchemy/Infura"
echo "   - ETHERSCAN_API_KEY: Get from etherscan.io"
echo ""
echo "2. Get Sepolia ETH from faucet:"
echo "   - https://sepoliafaucet.com/"
echo "   - https://faucet.quicknode.com/ethereum/sepolia"
echo ""
echo "3. Run deployment:"
echo "   ./deploy-sepolia.sh"
echo ""
echo "⚠️  Security reminder:"
echo "   - Never share your private key"
echo "   - Never commit .env to version control"
echo "   - Use a separate wallet for testing"

# Add .env to .gitignore if it doesn't exist
if [ ! -f .gitignore ]; then
    echo ".env" > .gitignore
    echo "🔒 Created .gitignore to protect .env file"
elif ! grep -q ".env" .gitignore; then
    echo ".env" >> .gitignore
    echo "🔒 Added .env to .gitignore"
fi
