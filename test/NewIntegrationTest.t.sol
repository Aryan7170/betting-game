// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/BettingGame.sol";
import "../script/DeployBettingGame.s.sol";
import "../script/Interactions.s.sol";
import "../script/HelperConfig.s.sol";
import "./mocks/MockVRFCoordinator.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract NewBettingGameIntegrationTest2 is Test {
    BettingGame public bettingGame;
    MockVRFCoordinator public mockVRFCoordinator;
    HelperConfig public helperConfig;
    
    address public owner = address(0x1);
    address public player1 = address(0x2);
    address public player2 = address(0x3);
    address public player3 = address(0x4);
    address public player4 = address(0x5);
    
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
        
        // Create mock VRF coordinator with consistent subscription ID
        mockVRFCoordinator = new MockVRFCoordinator();
        
        // Deploy the betting game directly with the mock coordinator
        bettingGame = new BettingGame(
            1, // subscription ID (consistent with mock)
            address(mockVRFCoordinator),
            bytes32(uint256(1)), // gas lane
            300000 // callback gas limit
        );
        
        // Fund the contract with 100 ETH for testing
        vm.deal(address(bettingGame), 100 ether);
        
        vm.stopPrank();
        
        // Fund players
        vm.deal(player1, 10 ether);
        vm.deal(player2, 10 ether);
        vm.deal(player3, 10 ether);
        vm.deal(player4, 10 ether);
    }
    
    function testFullGameFlowIntegration() public {
        // Test a complete game flow from bet placement to resolution
        uint256 initialContractBalance = address(bettingGame).balance;
        
        // Player 1 places a coin bet
        vm.startPrank(player1);
        vm.expectEmit(true, true, false, false);
        emit BetPlaced(0, player1, 0.1 ether, BettingGame.GameType.COIN, 0);
        bettingGame.placeCoinBet{value: 0.1 ether}(0);
        vm.stopPrank();
        
        // Verify bet was placed correctly
        BettingGame.Bet memory bet = bettingGame.getBet(0);
        assertEq(bet.player, player1);
        assertEq(bet.amount, 0.1 ether);
        assertEq(bet.prediction, 0);
        assertEq(uint256(bet.gameType), uint256(BettingGame.GameType.COIN));
        assertEq(uint256(bet.status), uint256(BettingGame.GameStatus.PENDING));
        
        // Contract balance should increase
        assertEq(address(bettingGame).balance, initialContractBalance + 0.1 ether);
        
        // Fulfill VRF request (simulate heads win)
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 0; // Results in heads (0)
        
        vm.expectEmit(true, true, false, false);
        emit BetResolved(0, player1, 0, true, 0.196 ether);
        mockVRFCoordinator.fulfillRandomWords(1, address(bettingGame), randomWords);
        
        // Verify bet was resolved correctly
        bet = bettingGame.getBet(0);
        assertEq(bet.result, 0);
        assertTrue(bet.won);
        assertEq(bet.payout, 0.196 ether); // 0.1 * 2 - 2% house edge
        assertEq(uint256(bet.status), uint256(BettingGame.GameStatus.COMPLETED));
        
        // Player should have received payout
        assertEq(address(bettingGame).balance, initialContractBalance + 0.1 ether - 0.196 ether);
    }
    
    function testMultiplePlayersIntegration() public {
        // Test multiple players betting simultaneously
        uint256 betAmount = 0.1 ether;
        
        // Multiple players place bets
        vm.startPrank(player1);
        bettingGame.placeCoinBet{value: betAmount}(0);
        vm.stopPrank();
        
        vm.startPrank(player2);
        bettingGame.placeCoinBet{value: betAmount}(1);
        vm.stopPrank();
        
        vm.startPrank(player3);
        bettingGame.placeDiceBet{value: betAmount}(4);
        vm.stopPrank();
        
        vm.startPrank(player4);
        bettingGame.placeDiceBet{value: betAmount}(2);
        vm.stopPrank();
        
        // Verify all bets were placed
        assertEq(bettingGame.nextBetId(), 4);
        
        // Fulfill all VRF requests
        uint256[] memory randomWords = new uint256[](1);
        
        // Player 1 wins
        randomWords[0] = 0;
        mockVRFCoordinator.fulfillRandomWords(1, address(bettingGame), randomWords);
        
        // Player 2 loses
        randomWords[0] = 0;
        mockVRFCoordinator.fulfillRandomWords(2, address(bettingGame), randomWords);
        
        // Player 3 wins (bet on 4, need randomWords[0] = 3 to get result 4)
        randomWords[0] = 3;
        mockVRFCoordinator.fulfillRandomWords(3, address(bettingGame), randomWords);
        
        // Player 4 loses (bet on 2, use randomWords[0] = 5 to get result 6)
        randomWords[0] = 5;
        mockVRFCoordinator.fulfillRandomWords(4, address(bettingGame), randomWords);
        
        // Verify results
        assertTrue(bettingGame.getBet(0).won);
        assertFalse(bettingGame.getBet(1).won);
        assertTrue(bettingGame.getBet(2).won);
        assertFalse(bettingGame.getBet(3).won);
        
        // Check player bet histories
        assertEq(bettingGame.getPlayerBets(player1).length, 1);
        assertEq(bettingGame.getPlayerBets(player2).length, 1);
        assertEq(bettingGame.getPlayerBets(player3).length, 1);
        assertEq(bettingGame.getPlayerBets(player4).length, 1);
    }
    
    function testHouseEdgeIntegration() public {
        // Test that house edge is properly applied
        uint256 betAmount = 1 ether;
        
        // Place a winning coin bet
        vm.startPrank(player1);
        bettingGame.placeCoinBet{value: betAmount}(0);
        vm.stopPrank();
        
        // Fulfill with winning result
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 0; // Win
        mockVRFCoordinator.fulfillRandomWords(1, address(bettingGame), randomWords);
        
        BettingGame.Bet memory bet = bettingGame.getBet(0);
        uint256 expectedPayout = (betAmount * 2 * (10000 - 200)) / 10000; // 2% house edge
        assertEq(bet.payout, expectedPayout);
        
        // Place a winning dice bet
        vm.startPrank(player2);
        bettingGame.placeDiceBet{value: betAmount}(3);
        vm.stopPrank();
        
        // Fulfill with winning result
        randomWords[0] = 2; // This will result in dice result = (2 % 6) + 1 = 3, which matches prediction 3
        mockVRFCoordinator.fulfillRandomWords(2, address(bettingGame), randomWords);
        
        bet = bettingGame.getBet(1);
        expectedPayout = (betAmount * 6 * (10000 - 200)) / 10000; // 2% house edge
        assertEq(bet.payout, expectedPayout);
    }
    
    function testHighVolumeIntegration() public {
        // Test handling of high volume betting scenarios with controlled randomness
        uint256 totalBets = 10;
        uint256 totalWinnings = 0;
        uint256 totalBetAmount = 0;
        
        // Place bets with controlled outcomes
        for (uint256 i = 0; i < totalBets; i++) {
            address player = address(uint160(0x1000 + (i % 4)));
            vm.deal(player, 1 ether);
            
            vm.startPrank(player);
            
            if (i % 2 == 0) {
                // Coin bet
                bettingGame.placeCoinBet{value: 0.05 ether}(0); // Always bet heads
                totalBetAmount += 0.05 ether;
            } else {
                // Dice bet
                bettingGame.placeDiceBet{value: 0.03 ether}(1); // Always bet 1
                totalBetAmount += 0.03 ether;
            }
            
            vm.stopPrank();
        }
        
        // Fulfill VRF requests with controlled results (50% win rate)
        for (uint256 i = 1; i <= totalBets; i++) {
            uint256[] memory randomWords = new uint256[](1);
            
            // Align with bet placement pattern:
            // i-1 % 2 == 0 means coin bet, i-1 % 2 == 1 means dice bet
            if ((i - 1) % 2 == 0) {
                // Coin bet - make every other one win
                if (i % 4 == 1) {
                    randomWords[0] = 0; // Coin wins (heads)
                } else {
                    randomWords[0] = 1; // Coin loses (tails)
                }
            } else {
                // Dice bet - make every other one win
                if (i % 4 == 0) {
                    randomWords[0] = 0; // Dice wins (result = 1)
                } else {
                    randomWords[0] = 1; // Dice loses (result = 2)
                }
            }
            
            mockVRFCoordinator.fulfillRandomWords(i, address(bettingGame), randomWords);
            
            // Calculate winnings
            BettingGame.Bet memory bet = bettingGame.getBet(i - 1);
            if (bet.won) {
                totalWinnings += bet.payout;
            }
        }
        
        // Verify game statistics
        (uint256 totalBetsCount, uint256 totalPayout, uint256 contractBalance, uint256 houseEdge) = 
            bettingGame.getGameStats();
        
        assertEq(totalBetsCount, totalBets);
        assertEq(totalPayout, totalWinnings);
        assertEq(houseEdge, 200); // 2% house edge
        
        // Verify contract balance integrity
        uint256 expectedBalance = 100 ether + totalBetAmount - totalWinnings;
        assertEq(contractBalance, expectedBalance);
        
        // Verify house edge is applied (total winnings should be less than theoretical maximum)
        // For this test pattern, we expect some wins and some losses
        assertGt(totalWinnings, 0); // Some players should win
        assertLt(totalWinnings, totalBetAmount * 10); // But not an unreasonable amount
    }
    
    function testDeploymentWorkflow() public {
        // Test that deployment creates a working BettingGame contract
        // Use the same MockVRFCoordinator as in the test setup
        
        // Deploy the betting game with mock coordinator
        BettingGame deployedGame = new BettingGame(
            1, // subscription ID
            address(mockVRFCoordinator),
            bytes32(uint256(1)), // gas lane
            300000 // callback gas limit
        );
        
        // Fund the contract
        vm.deal(address(deployedGame), 10 ether);
        
        // Verify deployment was successful
        assertTrue(address(deployedGame) != address(0));
        
        // Test that the deployed contract works
        vm.startPrank(player1);
        deployedGame.placeCoinBet{value: 0.1 ether}(0);
        vm.stopPrank();
        
        // Verify the bet was placed
        assertEq(deployedGame.nextBetId(), 1);
        
        BettingGame.Bet memory bet = deployedGame.getBet(0);
        assertEq(bet.player, player1);
        assertEq(bet.amount, 0.1 ether);
        assertEq(bet.prediction, 0);
        assertEq(uint256(bet.gameType), uint256(BettingGame.GameType.COIN));
    }
    
    function testVRFSubscriptionFlow() public {
        // Test VRF subscription creation and management
        
        // Create subscription directly on mock coordinator
        uint64 subId = mockVRFCoordinator.createSubscription();
        
        assertEq(subId, 1); // Should be the first subscription from this mock coordinator instance
        
        // Fund subscription directly using MockVRFCoordinator
        vm.prank(owner);
        mockVRFCoordinator.fundSubscription(subId, 3 ether);
        
        // Add consumer directly 
        vm.prank(owner);
        mockVRFCoordinator.addConsumer(subId, address(bettingGame));
        
        // Verify subscription setup worked by placing a bet
        vm.startPrank(player1);
        bettingGame.placeCoinBet{value: 0.1 ether}(0);
        vm.stopPrank();
        
        assertEq(bettingGame.nextBetId(), 1);
    }
    
    function testVRFIntegrationComplete() public {
        // Test VRF integration specifically
        vm.startPrank(player1);
        bettingGame.placeCoinBet{value: 0.1 ether}(0);
        vm.stopPrank();
        
        // Check that VRF request was made
        uint256 lastRequestId = mockVRFCoordinator.getLastRequestId();
        assertEq(lastRequestId, 1);
        
        // Bet should be pending
        BettingGame.Bet memory bet = bettingGame.getBet(0);
        assertEq(uint256(bet.status), uint256(BettingGame.GameStatus.PENDING));
        
        // Fulfill VRF request
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 123; // Random value
        mockVRFCoordinator.fulfillRandomWords(1, address(bettingGame), randomWords);
        
        // Bet should be resolved
        bet = bettingGame.getBet(0);
        assertEq(uint256(bet.status), uint256(BettingGame.GameStatus.COMPLETED));
        assertEq(bet.result, randomWords[0] % 2); // Should be 0 or 1 for coin
    }
    
    function testOwnerOperationsIntegration() public {
        // Test owner-only operations
        uint256 initialBalance = address(bettingGame).balance;
        
        // Non-owner cannot withdraw
        vm.startPrank(player1);
        vm.expectRevert();
        bettingGame.withdrawFunds(0.1 ether);
        vm.stopPrank();
        
        // Owner can withdraw
        vm.startPrank(owner);
        uint256 withdrawAmount = 1 ether;
        bettingGame.withdrawFunds(withdrawAmount);
        vm.stopPrank();
        
        // Check balance decreased
        assertEq(address(bettingGame).balance, initialBalance - withdrawAmount);
        
        // Test funding the contract
        vm.startPrank(player1);
        bettingGame.fundContract{value: 2 ether}();
        vm.stopPrank();
        
        // Check balance increased
        assertEq(address(bettingGame).balance, initialBalance - withdrawAmount + 2 ether);
    }
    
    function testScriptInteractionIntegration() public {
        // Test integration with mock VRF coordinator
        
        // Place bet directly on contract
        vm.prank(player1);
        vm.deal(player1, 1 ether);
        bettingGame.placeCoinBet{value: 0.1 ether}(0);
        
        // Verify bet was placed
        assertEq(bettingGame.nextBetId(), 1);
        
        // Fulfill using mock VRF coordinator directly
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 0; // This will result in a win
        mockVRFCoordinator.fulfillRandomWords(1, address(bettingGame), randomWords);
        
        // Verify bet was resolved
        BettingGame.Bet memory bet = bettingGame.getBet(0);
        assertEq(uint256(bet.status), uint256(BettingGame.GameStatus.COMPLETED));
        assertTrue(bet.won); // Should win with result 0
    }
    
    function testErrorHandlingIntegration() public {
        // Test error handling in integrated scenarios
        
        // Test invalid predictions
        vm.startPrank(player1);
        
        // Invalid coin prediction (must be 0 or 1)
        vm.expectRevert(BettingGame.BettingGame__InvalidPrediction.selector);
        bettingGame.placeCoinBet{value: 0.1 ether}(2);
        
        // Invalid dice prediction (must be 1-6)
        vm.expectRevert(BettingGame.BettingGame__InvalidPrediction.selector);
        bettingGame.placeDiceBet{value: 0.1 ether}(0);
        
        vm.expectRevert(BettingGame.BettingGame__InvalidPrediction.selector);
        bettingGame.placeDiceBet{value: 0.1 ether}(7);
        
        // Valid bets should work
        bettingGame.placeCoinBet{value: 0.1 ether}(0);
        bettingGame.placeCoinBet{value: 0.1 ether}(1);
        bettingGame.placeDiceBet{value: 0.1 ether}(1);
        bettingGame.placeDiceBet{value: 0.1 ether}(6);
        
        vm.stopPrank();
        
        // Verify all valid bets were placed
        assertEq(bettingGame.nextBetId(), 4);
    }
    
    function testCompleteGameSession() public {
        // Test a complete gaming session with multiple rounds
        uint256 sessionBets = 5;
        uint256 totalWinnings = 0;
        
        for (uint256 round = 0; round < sessionBets; round++) {
            // Player places bet
            vm.startPrank(player1);
            bettingGame.placeCoinBet{value: 0.1 ether}(0);
            vm.stopPrank();
            
            // Fulfill VRF request
            uint256[] memory randomWords = new uint256[](1);
            randomWords[0] = round % 2; // Alternate wins/losses
            mockVRFCoordinator.fulfillRandomWords(round + 1, address(bettingGame), randomWords);
            
            // Track winnings
            BettingGame.Bet memory bet = bettingGame.getBet(round);
            if (bet.won) {
                totalWinnings += bet.payout;
            }
        }
        
        // Verify session results
        assertEq(bettingGame.nextBetId(), sessionBets);
        assertEq(bettingGame.getPlayerBets(player1).length, sessionBets);
        
        // Check game statistics
        (uint256 totalBets, uint256 totalPayout, , ) = bettingGame.getGameStats();
        assertEq(totalBets, sessionBets);
        assertEq(totalPayout, totalWinnings);
    }
}
