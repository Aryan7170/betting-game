// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/BettingGame.sol";
import "./mocks/MockVRFCoordinator.sol";

contract BettingGameTest is Test {
    BettingGame public bettingGame;
    MockVRFCoordinator public mockVRFCoordinator;
    
    address public owner = address(0x1);
    address public player1 = address(0x2);
    address public player2 = address(0x3);
    
    uint64 constant SUBSCRIPTION_ID = 1;
    bytes32 constant GAS_LANE = bytes32(uint256(1));
    uint32 constant CALLBACK_GAS_LIMIT = 300000;
    
    event BetPlaced(
        uint256 indexed betId,
        address indexed player,
        uint256 amount,
        BettingGame.GameType gameType,
        uint256 prediction
    );
    
    event BetResolved(
        uint256 indexed betId,
        address indexed player,
        uint256 result,
        bool won,
        uint256 payout
    );
    
    function setUp() public {
        vm.startPrank(owner);
        
        mockVRFCoordinator = new MockVRFCoordinator();
        bettingGame = new BettingGame(
            SUBSCRIPTION_ID,
            address(mockVRFCoordinator),
            GAS_LANE,
            CALLBACK_GAS_LIMIT
        );
        
        // Fund the contract
        vm.deal(address(bettingGame), 10 ether);
        
        vm.stopPrank();
        
        // Fund players
        vm.deal(player1, 5 ether);
        vm.deal(player2, 5 ether);
    }
    
    function testDeployment() public {
        assertEq(bettingGame.owner(), owner);
        assertEq(bettingGame.MIN_BET(), 0.01 ether);
        assertEq(bettingGame.MAX_BET(), 1 ether);
        assertEq(bettingGame.HOUSE_EDGE(), 200); // 2%
        assertEq(bettingGame.nextBetId(), 0);
    }
    
    function testPlaceCoinBet() public {
        vm.startPrank(player1);
        
        uint256 betAmount = 0.1 ether;
        uint256 prediction = 0; // heads
        
        vm.expectEmit(true, true, false, true);
        emit BetPlaced(0, player1, betAmount, BettingGame.GameType.COIN, prediction);
        
        bettingGame.placeCoinBet{value: betAmount}(prediction);
        
        BettingGame.Bet memory bet = bettingGame.getBet(0);
        assertEq(bet.player, player1);
        assertEq(bet.amount, betAmount);
        assertEq(uint256(bet.gameType), uint256(BettingGame.GameType.COIN));
        assertEq(bet.prediction, prediction);
        assertEq(uint256(bet.status), uint256(BettingGame.GameStatus.PENDING));
        
        vm.stopPrank();
    }
    
    function testPlaceDiceBet() public {
        vm.startPrank(player1);
        
        uint256 betAmount = 0.1 ether;
        uint256 prediction = 3; // dice number
        
        vm.expectEmit(true, true, false, true);
        emit BetPlaced(0, player1, betAmount, BettingGame.GameType.DICE, prediction);
        
        bettingGame.placeDiceBet{value: betAmount}(prediction);
        
        BettingGame.Bet memory bet = bettingGame.getBet(0);
        assertEq(bet.player, player1);
        assertEq(bet.amount, betAmount);
        assertEq(uint256(bet.gameType), uint256(BettingGame.GameType.DICE));
        assertEq(bet.prediction, prediction);
        assertEq(uint256(bet.status), uint256(BettingGame.GameStatus.PENDING));
        
        vm.stopPrank();
    }
    
    function testBetTooLow() public {
        vm.startPrank(player1);
        
        vm.expectRevert(BettingGame.BettingGame__BetAmountTooLow.selector);
        bettingGame.placeCoinBet{value: 0.005 ether}(0);
        
        vm.stopPrank();
    }
    
    function testBetTooHigh() public {
        vm.startPrank(player1);
        
        vm.expectRevert(BettingGame.BettingGame__BetAmountTooHigh.selector);
        bettingGame.placeCoinBet{value: 1.1 ether}(0);
        
        vm.stopPrank();
    }
    
    function testInvalidCoinPrediction() public {
        vm.startPrank(player1);
        
        vm.expectRevert(BettingGame.BettingGame__InvalidPrediction.selector);
        bettingGame.placeCoinBet{value: 0.1 ether}(2);
        
        vm.stopPrank();
    }
    
    function testInvalidDicePrediction() public {
        vm.startPrank(player1);
        
        vm.expectRevert(BettingGame.BettingGame__InvalidPrediction.selector);
        bettingGame.placeDiceBet{value: 0.1 ether}(0);
        
        vm.expectRevert(BettingGame.BettingGame__InvalidPrediction.selector);
        bettingGame.placeDiceBet{value: 0.1 ether}(7);
        
        vm.stopPrank();
    }
    
    function testCoinBetWin() public {
        vm.startPrank(player1);
        
        uint256 betAmount = 0.1 ether;
        uint256 prediction = 0; // heads
        uint256 initialBalance = player1.balance;
        
        bettingGame.placeCoinBet{value: betAmount}(prediction);
        
        // Simulate VRF response with winning result
        uint256 requestId = mockVRFCoordinator.getLastRequestId();
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 0; // heads (matches prediction)
        
        vm.expectEmit(true, true, false, true);
        emit BetResolved(0, player1, 0, true, (betAmount * 2 * 9800) / 10000);
        
        mockVRFCoordinator.fulfillRandomWords(requestId, address(bettingGame), randomWords);
        
        BettingGame.Bet memory bet = bettingGame.getBet(0);
        assertTrue(bet.won);
        assertEq(bet.result, 0);
        assertEq(uint256(bet.status), uint256(BettingGame.GameStatus.COMPLETED));
        
        // Check payout
        uint256 expectedPayout = (betAmount * 2 * 9800) / 10000; // 2x with 2% house edge
        assertEq(bet.payout, expectedPayout);
        assertEq(player1.balance, initialBalance - betAmount + expectedPayout);
        
        vm.stopPrank();
    }
    
    function testCoinBetLose() public {
        vm.startPrank(player1);
        
        uint256 betAmount = 0.1 ether;
        uint256 prediction = 0; // heads
        uint256 initialBalance = player1.balance;
        
        bettingGame.placeCoinBet{value: betAmount}(prediction);
        
        // Simulate VRF response with losing result
        uint256 requestId = mockVRFCoordinator.getLastRequestId();
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 1; // tails (doesn't match prediction)
        
        vm.expectEmit(true, true, false, true);
        emit BetResolved(0, player1, 1, false, 0);
        
        mockVRFCoordinator.fulfillRandomWords(requestId, address(bettingGame), randomWords);
        
        BettingGame.Bet memory bet = bettingGame.getBet(0);
        assertFalse(bet.won);
        assertEq(bet.result, 1);
        assertEq(bet.payout, 0);
        assertEq(uint256(bet.status), uint256(BettingGame.GameStatus.COMPLETED));
        
        // Check balance (should only lose the bet amount)
        assertEq(player1.balance, initialBalance - betAmount);
        
        vm.stopPrank();
    }
    
    function testDiceBetWin() public {
        vm.startPrank(player1);
        
        uint256 betAmount = 0.1 ether;
        uint256 prediction = 3;
        uint256 initialBalance = player1.balance;
        
        bettingGame.placeDiceBet{value: betAmount}(prediction);
        
        // Simulate VRF response with winning result
        uint256 requestId = mockVRFCoordinator.getLastRequestId();
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 2; // Will result in dice roll of 3 (2 % 6 + 1 = 3)
        
        vm.expectEmit(true, true, false, true);
        emit BetResolved(0, player1, 3, true, (betAmount * 6 * 9800) / 10000);
        
        mockVRFCoordinator.fulfillRandomWords(requestId, address(bettingGame), randomWords);
        
        BettingGame.Bet memory bet = bettingGame.getBet(0);
        assertTrue(bet.won);
        assertEq(bet.result, 3);
        assertEq(uint256(bet.status), uint256(BettingGame.GameStatus.COMPLETED));
        
        // Check payout
        uint256 expectedPayout = (betAmount * 6 * 9800) / 10000; // 6x with 2% house edge
        assertEq(bet.payout, expectedPayout);
        assertEq(player1.balance, initialBalance - betAmount + expectedPayout);
        
        vm.stopPrank();
    }
    
    function testGetPlayerBets() public {
        vm.startPrank(player1);
        
        bettingGame.placeCoinBet{value: 0.1 ether}(0);
        bettingGame.placeDiceBet{value: 0.1 ether}(3);
        
        uint256[] memory playerBets = bettingGame.getPlayerBets(player1);
        assertEq(playerBets.length, 2);
        assertEq(playerBets[0], 0);
        assertEq(playerBets[1], 1);
        
        vm.stopPrank();
    }
    
    function testGetGameStats() public {
        vm.startPrank(player1);
        
        bettingGame.placeCoinBet{value: 0.1 ether}(0);
        bettingGame.placeDiceBet{value: 0.1 ether}(3);
        
        (uint256 totalBets, uint256 totalPayout, uint256 contractBalance, uint256 houseEdge) = bettingGame.getGameStats();
        assertEq(totalBets, 2);
        assertEq(totalPayout, 0); // No payouts yet
        assertEq(contractBalance, 10.2 ether); // 10 + 0.2 from bets
        assertEq(houseEdge, 200);
        
        vm.stopPrank();
    }
    
    function testWithdrawFunds() public {
        vm.startPrank(owner);
        
        uint256 initialBalance = owner.balance;
        uint256 withdrawAmount = 1 ether;
        
        bettingGame.withdrawFunds(withdrawAmount);
        
        assertEq(owner.balance, initialBalance + withdrawAmount);
        assertEq(address(bettingGame).balance, 10 ether - withdrawAmount);
        
        vm.stopPrank();
    }
    
    function testWithdrawFundsOnlyOwner() public {
        vm.startPrank(player1);
        
        vm.expectRevert("Only callable by owner");
        bettingGame.withdrawFunds(1 ether);
        
        vm.stopPrank();
    }
    
    function testCancelBet() public {
        vm.startPrank(player1);
        
        uint256 betAmount = 0.1 ether;
        uint256 initialBalance = player1.balance;
        
        bettingGame.placeCoinBet{value: betAmount}(0);
        
        vm.stopPrank();
        
        vm.startPrank(owner);
        
        bettingGame.cancelBet(0);
        
        BettingGame.Bet memory bet = bettingGame.getBet(0);
        assertEq(uint256(bet.status), uint256(BettingGame.GameStatus.CANCELLED));
        assertEq(player1.balance, initialBalance); // Refunded
        
        vm.stopPrank();
    }
    
    function testInsufficientContractBalance() public {
        // Withdraw most funds to simulate insufficient balance
        vm.startPrank(owner);
        bettingGame.withdrawFunds(9.95 ether); // Leave only 0.05 ether
        vm.stopPrank();
        
        vm.startPrank(player1);
        
        vm.expectRevert(BettingGame.BettingGame__InsufficientContractBalance.selector);
        bettingGame.placeCoinBet{value: 0.1 ether}(0); // Requires 0.196 ether payout
        
        vm.stopPrank();
    }
    
    function testReceiveFunction() public {
        uint256 initialBalance = address(bettingGame).balance;
        
        vm.startPrank(player1);
        (bool success, ) = address(bettingGame).call{value: 1 ether}("");
        assertTrue(success);
        
        assertEq(address(bettingGame).balance, initialBalance + 1 ether);
        
        vm.stopPrank();
    }
}
