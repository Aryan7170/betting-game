// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/BettingGame.sol";
import "./mocks/MockVRFCoordinator.sol";

contract BettingGameIntegrationTest is Test {
    BettingGame public bettingGame;
    MockVRFCoordinator public mockVRFCoordinator;
    
    address public owner = address(0x1);
    address public player1 = address(0x2);
    address public player2 = address(0x3);
    address public player3 = address(0x4);
    
    uint64 constant SUBSCRIPTION_ID = 1;
    bytes32 constant GAS_LANE = bytes32(uint256(1));
    uint32 constant CALLBACK_GAS_LIMIT = 300000;
    
    function setUp() public {
        vm.startPrank(owner);
        
        mockVRFCoordinator = new MockVRFCoordinator();
        bettingGame = new BettingGame(
            SUBSCRIPTION_ID,
            address(mockVRFCoordinator),
            GAS_LANE,
            CALLBACK_GAS_LIMIT
        );
        
        // Fund the contract with 20 ETH
        vm.deal(address(bettingGame), 20 ether);
        
        vm.stopPrank();
        
        // Fund players
        vm.deal(player1, 10 ether);
        vm.deal(player2, 10 ether);
        vm.deal(player3, 10 ether);
    }
    
    function testFullGameFlow() public {
        // Track initial balances
        uint256 player1InitialBalance = player1.balance;
        uint256 player2InitialBalance = player2.balance;
        uint256 player3InitialBalance = player3.balance;
        
        // Player 1: Place winning coin bet
        vm.startPrank(player1);
        bettingGame.placeCoinBet{value: 0.5 ether}(0); // Bet on heads
        vm.stopPrank();
        
        // Player 2: Place losing dice bet
        vm.startPrank(player2);
        bettingGame.placeDiceBet{value: 0.2 ether}(3); // Bet on rolling 3
        vm.stopPrank();
        
        // Player 3: Place winning dice bet
        vm.startPrank(player3);
        bettingGame.placeDiceBet{value: 0.1 ether}(5); // Bet on rolling 5
        vm.stopPrank();
        
        // Verify bets are placed
        assertEq(bettingGame.nextBetId(), 3);
        
        // Fulfill VRF requests
        uint256 requestId1 = 1; // Player 1's coin bet
        uint256 requestId2 = 2; // Player 2's dice bet
        uint256 requestId3 = 3; // Player 3's dice bet
        
        // Player 1 wins coin flip (heads)
        uint256[] memory randomWords1 = new uint256[](1);
        randomWords1[0] = 0; // Results in heads
        mockVRFCoordinator.fulfillRandomWords(requestId1, address(bettingGame), randomWords1);
        
        // Player 2 loses dice roll (rolls 1 instead of 3)
        uint256[] memory randomWords2 = new uint256[](1);
        randomWords2[0] = 0; // Results in 1 (0 % 6 + 1 = 1)
        mockVRFCoordinator.fulfillRandomWords(requestId2, address(bettingGame), randomWords2);
        
        // Player 3 wins dice roll (rolls 5)
        uint256[] memory randomWords3 = new uint256[](1);
        randomWords3[0] = 4; // Results in 5 (4 % 6 + 1 = 5)
        mockVRFCoordinator.fulfillRandomWords(requestId3, address(bettingGame), randomWords3);
        
        // Verify bet results
        BettingGame.Bet memory bet1 = bettingGame.getBet(0);
        BettingGame.Bet memory bet2 = bettingGame.getBet(1);
        BettingGame.Bet memory bet3 = bettingGame.getBet(2);
        
        // Player 1 won coin flip
        assertTrue(bet1.won);
        assertEq(bet1.result, 0);
        assertEq(bet1.payout, (0.5 ether * 2 * 9800) / 10000); // 0.98 ETH
        
        // Player 2 lost dice roll
        assertFalse(bet2.won);
        assertEq(bet2.result, 1);
        assertEq(bet2.payout, 0);
        
        // Player 3 won dice roll
        assertTrue(bet3.won);
        assertEq(bet3.result, 5);
        assertEq(bet3.payout, (0.1 ether * 6 * 9800) / 10000); // 0.588 ETH
        
        // Verify player balances
        assertEq(player1.balance, player1InitialBalance - 0.5 ether + bet1.payout);
        assertEq(player2.balance, player2InitialBalance - 0.2 ether); // Lost bet
        assertEq(player3.balance, player3InitialBalance - 0.1 ether + bet3.payout);
        
        // Verify game statistics
        (uint256 totalBets, uint256 totalPayout, uint256 contractBalance, uint256 houseEdge) = bettingGame.getGameStats();
        assertEq(totalBets, 3);
        assertEq(totalPayout, bet1.payout + bet3.payout);
        assertEq(houseEdge, 200); // 2%
        
        // Verify contract balance
        uint256 expectedBalance = 20 ether + 0.8 ether - totalPayout; // Initial + bets - payouts
        assertEq(contractBalance, expectedBalance);
        
        // Verify player bet tracking
        uint256[] memory player1Bets = bettingGame.getPlayerBets(player1);
        uint256[] memory player2Bets = bettingGame.getPlayerBets(player2);
        uint256[] memory player3Bets = bettingGame.getPlayerBets(player3);
        
        assertEq(player1Bets.length, 1);
        assertEq(player1Bets[0], 0);
        
        assertEq(player2Bets.length, 1);
        assertEq(player2Bets[0], 1);
        
        assertEq(player3Bets.length, 1);
        assertEq(player3Bets[0], 2);
    }
    
    function testMultipleBetsPerPlayer() public {
        vm.startPrank(player1);
        
        // Place multiple bets
        bettingGame.placeCoinBet{value: 0.1 ether}(0);
        bettingGame.placeCoinBet{value: 0.2 ether}(1);
        bettingGame.placeDiceBet{value: 0.15 ether}(4);
        
        vm.stopPrank();
        
        // Verify bet tracking
        uint256[] memory player1Bets = bettingGame.getPlayerBets(player1);
        assertEq(player1Bets.length, 3);
        assertEq(player1Bets[0], 0);
        assertEq(player1Bets[1], 1);
        assertEq(player1Bets[2], 2);
        
        // Verify bet details
        BettingGame.Bet memory bet1 = bettingGame.getBet(0);
        BettingGame.Bet memory bet2 = bettingGame.getBet(1);
        BettingGame.Bet memory bet3 = bettingGame.getBet(2);
        
        assertEq(bet1.amount, 0.1 ether);
        assertEq(bet1.prediction, 0);
        assertEq(uint256(bet1.gameType), uint256(BettingGame.GameType.COIN));
        
        assertEq(bet2.amount, 0.2 ether);
        assertEq(bet2.prediction, 1);
        assertEq(uint256(bet2.gameType), uint256(BettingGame.GameType.COIN));
        
        assertEq(bet3.amount, 0.15 ether);
        assertEq(bet3.prediction, 4);
        assertEq(uint256(bet3.gameType), uint256(BettingGame.GameType.DICE));
    }
    
    function testHouseEdgeEffect() public {
        uint256 initialContractBalance = address(bettingGame).balance;
        
        // Simulate many bets with predetermined outcomes
        // This should show the house edge effect over time
        
        uint256 totalBetAmount = 0;
        uint256 totalWinnings = 0;
        
        // Place 10 coin bets, half winning
        for (uint256 i = 0; i < 10; i++) {
            address player = address(uint160(0x1000 + i));
            vm.deal(player, 1 ether);
            
            vm.startPrank(player);
            bettingGame.placeCoinBet{value: 0.1 ether}(0); // All bet on heads
            vm.stopPrank();
            
            totalBetAmount += 0.1 ether;
            
            // Fulfill VRF - alternate between win/lose
            uint256[] memory randomWords = new uint256[](1);
            randomWords[0] = i % 2; // 0 for heads (win), 1 for tails (lose)
            mockVRFCoordinator.fulfillRandomWords(i + 1, address(bettingGame), randomWords);
            
            if (i % 2 == 0) { // Wins
                totalWinnings += (0.1 ether * 2 * 9800) / 10000; // 0.196 ETH
            }
        }
        
        // Verify house edge effect
        (uint256 totalBets, uint256 totalPayout, uint256 contractBalance, uint256 houseEdge) = bettingGame.getGameStats();
        
        assertEq(totalBets, 10);
        assertEq(totalPayout, totalWinnings);
        
        // Contract should have initial balance + all bets - payouts
        uint256 expectedContractBalance = initialContractBalance + totalBetAmount - totalWinnings;
        assertEq(contractBalance, expectedContractBalance);
        
        // Verify the house edge is working (house should profit)
        assertGt(totalBetAmount, totalWinnings);
    }
}
