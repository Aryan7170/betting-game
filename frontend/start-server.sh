#!/bin/bash

# Simple server setup script for Betting Game Frontend

echo "🎲 Betting Game Frontend Server Setup"
echo "===================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to start a simple HTTP server
start_server() {
    PORT=${1:-8080}
    
    echo "Starting server on port $PORT..."
    echo "📱 Frontend will be available at: http://localhost:$PORT"
    echo "🔗 Open this URL in your browser to use the Betting Game DApp"
    echo ""
    echo "⚠️  Make sure to:"
    echo "   1. Have MetaMask installed in your browser"
    echo "   2. Deploy the smart contract first"
    echo "   3. Enter the contract address in the frontend"
    echo ""
    echo "Press Ctrl+C to stop the server"
    echo ""
    
    if command_exists python3; then
        echo "🐍 Using Python 3 server..."
        python3 -m http.server $PORT
    elif command_exists python; then
        echo "🐍 Using Python server..."
        python -m http.server $PORT
    elif command_exists node; then
        echo "🟢 Using Node.js server..."
        npx http-server -p $PORT
    else
        echo "❌ No suitable server found. Please install Python or Node.js"
        echo "   - Python: https://www.python.org/downloads/"
        echo "   - Node.js: https://nodejs.org/en/download/"
        exit 1
    fi
}

# Check if port is provided
if [ $# -eq 0 ]; then
    start_server 8080
else
    start_server $1
fi
