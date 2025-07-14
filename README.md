# Betting Game - Dice & Coin Flip with Chainlink VRF

A decentralized betting game built on Ethereum using Foundry and Chainlink VRF for provably fair randomness. Players can bet on coin flips or dice rolls with transparent, verifiable outcomes.

## Features

- **Coin Flip Betting**: Bet on heads (0) or tails (1) with 2x payout
- **Dice Roll Betting**: Bet on numbers 1-6 with 6x payout
- **Chainlink VRF**: Cryptographically secure randomness
- **House Edge**: 2% house edge built into payouts
- **Bet Limits**: Minimum 0.01 ETH, Maximum 1 ETH per bet
- **Emergency Functions**: Owner can cancel pending bets and withdraw funds

## Smart Contract Architecture

### Core Components

- **BettingGame.sol**: Main contract handling bets, payouts, and game logic
- **Chainlink VRF Integration**: Uses VRFConsumerBaseV2 for random number generation
- **Owner Controls**: Emergency functions and fund management

### Game Types

1. **Coin Flip**
   - Prediction: 0 (heads) or 1 (tails)
   - Payout: 2x bet amount (minus 2% house edge)
   - Win Rate: 50%

2. **Dice Roll**
   - Prediction: 1, 2, 3, 4, 5, or 6
   - Payout: 6x bet amount (minus 2% house edge)
   - Win Rate: 16.67%

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/) (for scripts)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd betting-game
```

2. Install dependencies:
```bash
forge install
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

### Environment Variables

Create a `.env` file with:

```bash
# Deployment
PRIVATE_KEY=your_private_key_here
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your-infura-key
ETHERSCAN_API_KEY=your_etherscan_api_key

# Chainlink VRF Configuration (Sepolia)
VRF_COORDINATOR=0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
VRF_KEYHASH=0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c
VRF_SUBSCRIPTION_ID=your_subscription_id
VRF_CALLBACK_GAS_LIMIT=300000
```

### Testing

Run the comprehensive test suite:

```bash
# Run all tests
forge test

# Run tests with verbose output
forge test -vvv

# Run specific test file
forge test --match-path test/BettingGameTest.t.sol

# Run with gas reporting
forge test --gas-report
```

### Deployment

The project now uses a unified deployment system with `HelperConfig` for seamless deployment across networks.

#### Quick Start with Makefile

```bash
# Deploy to local Anvil (auto-detects and deploys MockVRF)
make deploy-local

# Deploy to Sepolia testnet (requires VRF subscription)
make deploy-sepolia

# Deploy to Ethereum mainnet
make deploy-mainnet
```

#### Manual Deployment

**Local Development (Anvil)**:
```bash
# Start Anvil
anvil

# Deploy (automatically uses MockVRF)
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

**Sepolia Testnet**:
1. Set up Chainlink VRF Subscription:
   - Go to [Chainlink VRF](https://vrf.chain.link/)
   - Create a subscription and fund with LINK tokens
   - Update subscription ID in `HelperConfig.s.sol`

2. Deploy:
```bash
forge script script/Deploy.s.sol --rpc-url https://eth-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

3. Add deployed contract as VRF consumer in your subscription

#### Network Configuration

The `HelperConfig` automatically handles:
- ✅ VRF Coordinator addresses for each network
- ✅ Gas lane configurations
- ✅ Mock VRF deployment for local testing
- ✅ Subscription ID management
- ✅ Deployment key management

Supported networks:
- Anvil Local (Chain ID: 31337) - Uses MockVRF
- Sepolia Testnet (Chain ID: 11155111)
- Ethereum Mainnet (Chain ID: 1)
- Polygon Mainnet (Chain ID: 137)
- Arbitrum One (Chain ID: 42161)

## Usage

### Placing Bets

**Coin Flip Bet**:
```solidity
// Bet 0.1 ETH on heads (0)
bettingGame.placeCoinBet{value: 0.1 ether}(0);

// Bet 0.1 ETH on tails (1)
bettingGame.placeCoinBet{value: 0.1 ether}(1);
```

**Dice Roll Bet**:
```solidity
// Bet 0.1 ETH on rolling a 3
bettingGame.placeDiceBet{value: 0.1 ether}(3);
```

### Viewing Game Data

```solidity
// Get bet details
BettingGame.Bet memory bet = bettingGame.getBet(betId);

// Get all player bets
uint256[] memory playerBets = bettingGame.getPlayerBets(playerAddress);

// Get game statistics
(uint256 totalBets, uint256 totalPayout, uint256 contractBalance, uint256 houseEdge) = bettingGame.getGameStats();
```

## Game Flow

1. **Player places bet**: Calls `placeCoinBet()` or `placeDiceBet()` with ETH
2. **VRF request**: Contract requests random number from Chainlink VRF
3. **Random fulfillment**: VRF Coordinator calls back with random number
4. **Result calculation**: Contract determines win/loss and processes payout
5. **Payout**: If won, ETH is automatically sent to player

## Security Features

- **Chainlink VRF**: Cryptographically secure, tamper-proof randomness
- **Access Control**: Owner-only functions for emergency situations
- **Input Validation**: Comprehensive checks for bet amounts and predictions
- **Reentrancy Protection**: Safe external calls and state management
- **Balance Checks**: Ensures contract can cover potential payouts

## Gas Optimization

- **Efficient Storage**: Packed structs and optimized storage layout
- **Minimal External Calls**: Batched operations where possible
- **Gas Limit Controls**: Configurable callback gas limits

## Error Handling

The contract includes comprehensive error handling:

- `BettingGame__BetAmountTooLow()`: Bet below minimum
- `BettingGame__BetAmountTooHigh()`: Bet above maximum
- `BettingGame__InsufficientContractBalance()`: Contract cannot cover payout
- `BettingGame__InvalidPrediction()`: Invalid prediction value
- `BettingGame__BetNotFound()`: Bet ID doesn't exist
- `BettingGame__OnlyPendingBets()`: Operation only valid for pending bets
- `BettingGame__WithdrawFailed()`: ETH transfer failed

## Events

- `BetPlaced`: Emitted when a bet is placed
- `BetResolved`: Emitted when bet result is determined
- `FundsWithdrawn`: Emitted when owner withdraws funds
- `FundsDeposited`: Emitted when funds are added to contract

## Owner Functions

- `withdrawFunds(uint256 amount)`: Withdraw funds from contract
- `cancelBet(uint256 betId)`: Cancel a pending bet (emergency only)

## Testing Strategy

The project includes comprehensive tests covering:

- **Unit Tests**: Individual function testing
- **Integration Tests**: Full game flow testing
- **Edge Cases**: Error conditions and boundary testing
- **Mock VRF**: Deterministic testing with mock coordinator

## Deployment Addresses

### Sepolia Testnet
- Contract: `TBD`
- VRF Coordinator: `0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License

## Disclaimer

This is a educational/demonstration project. Gambling may be illegal in your jurisdiction. Use at your own risk.

## Support

For questions or issues, please open a GitHub issue.
