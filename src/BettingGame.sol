// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

/**
 * @title BettingGame
 * @dev A dice and coin betting game using Chainlink VRF for randomness
 */
contract BettingGame is VRFConsumerBaseV2, ConfirmedOwner {
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    
    // VRF Configuration
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    
    // Game configuration
    uint256 public constant HOUSE_EDGE = 200; // 2% house edge (200 / 10000)
    uint256 public constant MIN_BET = 0.0001 ether;
    uint256 public constant MAX_BET = 100 ether;
    
    // Game states
    enum GameType { COIN, DICE }
    enum GameStatus { PENDING, COMPLETED, CANCELLED }
    
    struct Bet {
        address player;
        uint256 amount;
        GameType gameType;
        uint256 prediction; // 0 for heads, 1 for tails (coin) or 1-6 for dice
        uint256 result;
        bool won;
        GameStatus status;
        uint256 payout;
        uint256 timestamp;
    }
    
    // Storage
    mapping(uint256 => Bet) public bets;
    mapping(address => uint256[]) public playerBets;
    uint256 public nextBetId;
    uint256 public totalBets;
    uint256 public totalPayout;
    
    // Events
    event BetPlaced(
        uint256 indexed betId,
        address indexed player,
        uint256 amount,
        GameType gameType,
        uint256 prediction
    );
    
    event BetResolved(
        uint256 indexed betId,
        address indexed player,
        uint256 result,
        bool won,
        uint256 payout
    );
    
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event FundsDeposited(address indexed depositor, uint256 amount);
    
    // Custom errors
    error BettingGame__BetAmountTooLow();
    error BettingGame__BetAmountTooHigh();
    error BettingGame__InsufficientContractBalance();
    error BettingGame__InvalidPrediction();
    error BettingGame__BetNotFound();
    error BettingGame__OnlyPendingBets();
    error BettingGame__WithdrawFailed();
    
    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 gasLane,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) ConfirmedOwner(msg.sender) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
    }
    
    /**
     * @dev Allow contract to receive ETH for betting pool
     */
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Public function to fund the contract (easier for Remix interaction)
     */
    function fundContract() external payable {
        require(msg.value > 0, "Must send some ETH");
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    /**
     * @dev Place a coin flip bet
     * @param prediction 0 for heads, 1 for tails
     */
    function placeCoinBet(uint256 prediction) external payable {
        if (msg.value < MIN_BET) revert BettingGame__BetAmountTooLow();
        if (msg.value > MAX_BET) revert BettingGame__BetAmountTooHigh();
        if (prediction > 1) revert BettingGame__InvalidPrediction();
        
        // Calculate potential payout (2x bet minus house edge)
        uint256 potentialPayout = (msg.value * 2 * (10000 - HOUSE_EDGE)) / 10000;
        
        // Check if contract has enough balance to pay out
        if (address(this).balance < potentialPayout) {
            revert BettingGame__InsufficientContractBalance();
        }
        
        uint256 betId = nextBetId++;
        bets[betId] = Bet({
            player: msg.sender,
            amount: msg.value,
            gameType: GameType.COIN,
            prediction: prediction,
            result: 0,
            won: false,
            status: GameStatus.PENDING,
            payout: 0,
            timestamp: block.timestamp
        });
        
        playerBets[msg.sender].push(betId);
        totalBets++;
        
        emit BetPlaced(betId, msg.sender, msg.value, GameType.COIN, prediction);
        
        // Request random number
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        
        // Store the mapping of requestId to betId
        requestIdToBetId[requestId] = betId;
    }
    
    /**
     * @dev Place a dice roll bet
     * @param prediction number between 1-6
     */
    function placeDiceBet(uint256 prediction) external payable {
        if (msg.value < MIN_BET) revert BettingGame__BetAmountTooLow();
        if (msg.value > MAX_BET) revert BettingGame__BetAmountTooHigh();
        if (prediction < 1 || prediction > 6) revert BettingGame__InvalidPrediction();
        
        // Calculate potential payout (6x bet minus house edge)
        uint256 potentialPayout = (msg.value * 6 * (10000 - HOUSE_EDGE)) / 10000;
        
        // Check if contract has enough balance to pay out
        if (address(this).balance < potentialPayout) {
            revert BettingGame__InsufficientContractBalance();
        }
        
        uint256 betId = nextBetId++;
        bets[betId] = Bet({
            player: msg.sender,
            amount: msg.value,
            gameType: GameType.DICE,
            prediction: prediction,
            result: 0,
            won: false,
            status: GameStatus.PENDING,
            payout: 0,
            timestamp: block.timestamp
        });
        
        playerBets[msg.sender].push(betId);
        totalBets++;
        
        emit BetPlaced(betId, msg.sender, msg.value, GameType.DICE, prediction);
        
        // Request random number
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        
        // Store the mapping of requestId to betId
        requestIdToBetId[requestId] = betId;
    }
    
    // Mapping to track VRF requests
    mapping(uint256 => uint256) private requestIdToBetId;
    
    /**
     * @dev Callback function used by VRF Coordinator
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 betId = requestIdToBetId[requestId];
        Bet storage bet = bets[betId];
        
        if (bet.status != GameStatus.PENDING) {
            revert BettingGame__OnlyPendingBets();
        }
        
        uint256 randomResult = randomWords[0];
        bool won = false;
        uint256 payout = 0;
        
        if (bet.gameType == GameType.COIN) {
            // Coin flip: 0 = heads, 1 = tails
            uint256 coinResult = randomResult % 2;
            bet.result = coinResult;
            
            if (coinResult == bet.prediction) {
                won = true;
                payout = (bet.amount * 2 * (10000 - HOUSE_EDGE)) / 10000;
            }
        } else if (bet.gameType == GameType.DICE) {
            // Dice roll: 1-6
            uint256 diceResult = (randomResult % 6) + 1;
            bet.result = diceResult;
            
            if (diceResult == bet.prediction) {
                won = true;
                payout = (bet.amount * 6 * (10000 - HOUSE_EDGE)) / 10000;
            }
        }
        
        bet.won = won;
        bet.payout = payout;
        bet.status = GameStatus.COMPLETED;
        
        if (won && payout > 0) {
            totalPayout += payout;
            (bool success, ) = bet.player.call{value: payout}("");
            if (!success) revert BettingGame__WithdrawFailed();
        }
        
        emit BetResolved(betId, bet.player, bet.result, won, payout);
    }
    
    /**
     * @dev Get bet details
     */
    function getBet(uint256 betId) external view returns (Bet memory) {
        if (betId >= nextBetId) revert BettingGame__BetNotFound();
        return bets[betId];
    }
    
    /**
     * @dev Get all bet IDs for a player
     */
    function getPlayerBets(address player) external view returns (uint256[] memory) {
        return playerBets[player];
    }
    
    /**
     * @dev Get contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Get game statistics
     */
    function getGameStats() external view returns (
        uint256 totalBetsCount,
        uint256 totalPayoutAmount,
        uint256 contractBalance,
        uint256 houseEdge
    ) {
        return (totalBets, totalPayout, address(this).balance, HOUSE_EDGE);
    }
    
    /**
     * @dev Owner can withdraw funds from the contract
     */
    function withdrawFunds(uint256 amount) external onlyOwner {
        if (amount > address(this).balance) {
            revert BettingGame__InsufficientContractBalance();
        }
        
        (bool success, ) = owner().call{value: amount}("");
        if (!success) revert BettingGame__WithdrawFailed();
        
        emit FundsWithdrawn(owner(), amount);
    }
    
    /**
     * @dev Emergency function to cancel a pending bet (only owner)
     */
    function cancelBet(uint256 betId) external onlyOwner {
        if (betId >= nextBetId) revert BettingGame__BetNotFound();
        
        Bet storage bet = bets[betId];
        if (bet.status != GameStatus.PENDING) {
            revert BettingGame__OnlyPendingBets();
        }
        
        bet.status = GameStatus.CANCELLED;
        
        // Refund the player
        (bool success, ) = bet.player.call{value: bet.amount}("");
        if (!success) revert BettingGame__WithdrawFailed();
    }
}
