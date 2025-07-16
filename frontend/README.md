# Betting Game Frontend

A modern, responsive web interface for the Betting Game smart contract. This frontend allows users to connect their MetaMask wallet and place bets on coin flips and dice rolls.

## Features

- **Wallet Integration**: Connect MetaMask wallet to interact with the betting game
- **Two Game Types**: 
  - Coin Flip: Bet on heads or tails (2x payout with 2% house edge)
  - Dice Roll: Bet on numbers 1-6 (6x payout with 2% house edge)
- **Real-time Updates**: Live game statistics and bet history
- **Event Listening**: Real-time notifications for bet placements and results
- **Responsive Design**: Works on desktop and mobile devices
- **Configuration**: Easy contract address configuration

## Setup Instructions

### Prerequisites
- MetaMask browser extension installed
- Access to a deployed BettingGame smart contract

### Quick Start
1. Open `index.html` in your web browser
2. Enter your deployed contract address in the configuration section
3. Click "Update Configuration"
4. Connect your MetaMask wallet
5. Start betting!

### Contract Address Configuration
1. Deploy your BettingGame contract using the scripts in the parent directory
2. Copy the deployed contract address
3. Enter it in the "Contract Address" field in the frontend
4. Click "Update Configuration"

The contract address will be saved in local storage for future sessions.

## Usage

### Connecting Your Wallet
1. Click "Connect Wallet" button
2. Approve the connection in MetaMask
3. Your wallet address and balance will be displayed

### Placing Bets

#### Coin Flip
1. Enter bet amount in ETH
2. Select "Heads" or "Tails"
3. Click "Place Coin Bet"
4. Confirm transaction in MetaMask

#### Dice Roll
1. Enter bet amount in ETH
2. Select a number from 1-6
3. Click "Place Dice Bet"
4. Confirm transaction in MetaMask

### Viewing Results
- Bet history shows all your past bets with results
- Statistics display total bets, payouts, and your wins
- Real-time notifications show bet outcomes

## Technical Details

### Smart Contract Integration
- Uses ethers.js v6 for blockchain interaction
- Listens for contract events for real-time updates
- Handles transaction confirmations and error cases

### Supported Networks
- Ethereum mainnet
- Ethereum testnets (Goerli, Sepolia)
- Local development networks (Hardhat, Ganache)

### Security Features
- Input validation for bet amounts and predictions
- Contract address validation
- Safe transaction handling with proper error messages

## File Structure

```
frontend/
├── index.html          # Main HTML file with UI
├── app.js              # JavaScript application logic
├── package.json        # Node.js dependencies (for development)
├── vite.config.js      # Vite configuration (for development)
└── README.md           # This file
```

## Development

### With Build Tools (Optional)
If you want to use build tools for development:

```bash
npm install
npm run dev
```

### Without Build Tools
Simply open `index.html` in your browser. The app uses CDN-hosted libraries and doesn't require a build process.

## Contract ABI

The frontend includes the necessary ABI for interacting with the BettingGame contract:
- `placeCoinBet(uint256 prediction)`
- `placeDiceBet(uint256 prediction)`
- `getBet(uint256 betId)`
- `getPlayerBets(address player)`
- `getContractBalance()`
- Event listeners for `BetPlaced` and `BetResolved`

## Troubleshooting

### Common Issues

1. **"Please install MetaMask"**
   - Install MetaMask browser extension
   - Refresh the page

2. **"Error loading game stats"**
   - Check if contract address is correct
   - Ensure you're on the correct network
   - Verify contract is deployed

3. **Transaction failures**
   - Check wallet balance
   - Ensure bet amount is within limits (0.0001 - 100 ETH)
   - Verify contract has sufficient balance for potential payouts

4. **Network issues**
   - Switch to the correct network in MetaMask
   - Check network connectivity

## Browser Support

- Chrome (recommended)
- Firefox
- Safari
- Edge

## License

This frontend is part of the Betting Game project and follows the same license as the smart contract.
