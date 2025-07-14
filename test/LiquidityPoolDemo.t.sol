// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/BettingGame.sol";
import "./mocks/MockVRFCoordinator.sol";

contract LiquidityPoolDemo is Test {
    BettingGame public bettingGame;
    MockVRFCoordinator public mockVRFCoordinator;
    
    address public owner = address(0x1);
    address public player1 = address(0x2);
    address public player2 = address(0x3);
    address public player3 = address(0x4);
    
    function setUp() public {
        vm.startPrank(owner);
        
        mockVRFCoordinator = new MockVRFCoordinator();
        bettingGame = new BettingGame(
            1,
            address(mockVRFCoordinator),
            bytes32(uint256(1)),
            300000
        );
        
        // Start with 2 ETH in contract (initial liquidity)
        vm.deal(address(bettingGame), 2 ether);
        
        vm.stopPrank();
        
        // Fund players
        vm.deal(player1, 1 ether);
        vm.deal(player2, 1 ether);
        vm.deal(player3, 1 ether);
    }
    
    function testLiquidityPoolFlow() public {
        console.log("=== LIQUIDITY POOL DEMONSTRATION ===");
        console.log("Initial contract balance: %s ETH", address(bettingGame).balance / 1e18);
        console.log("");
        
        // SCENARIO 1: Player loses - their ETH stays in contract
        console.log("--- SCENARIO 1: Player 1 loses 0.5 ETH ---");
        uint256 contractBalanceBefore = address(bettingGame).balance;
        
        vm.startPrank(player1);
        bettingGame.placeCoinBet{value: 0.5 ether}(0); // Bet on heads
        vm.stopPrank();
        
        console.log("After bet placed - Contract balance: %s ETH", address(bettingGame).balance / 1e18);
        
        // Make player lose (result = 1 = tails)
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 1; // tails - player loses
        mockVRFCoordinator.fulfillRandomWords(1, address(bettingGame), randomWords);
        
        console.log("After player loses - Contract balance: %s ETH", address(bettingGame).balance / 1e18);
        console.log("Player 1 balance: %s ETH", player1.balance / 1e18);
        console.log("Lost wager of 0.5 ETH now available for future payouts!");
        console.log("");
        
        // SCENARIO 2: Player wins - gets paid from liquidity pool
        console.log("--- SCENARIO 2: Player 2 wins 0.3 ETH bet ---");
        
        vm.startPrank(player2);
        bettingGame.placeCoinBet{value: 0.3 ether}(0); // Bet on heads
        vm.stopPrank();
        
        console.log("After bet placed - Contract balance: %s ETH", address(bettingGame).balance / 1e18);
        
        // Make player win (result = 0 = heads)
        randomWords[0] = 0; // heads - player wins
        mockVRFCoordinator.fulfillRandomWords(2, address(bettingGame), randomWords);
        
        uint256 expectedPayout = (0.3 ether * 2 * 9800) / 10000; // 0.588 ETH
        console.log("After player wins - Contract balance: %s ETH", address(bettingGame).balance / 1e18);
        console.log("Player 2 balance: %s ETH", player2.balance / 1e18);
        console.log("Payout of %s ETH came from liquidity pool!", expectedPayout / 1e18);
        console.log("");
        
        // SCENARIO 3: Show how house edge accumulates
        console.log("--- SCENARIO 3: House edge accumulation ---");
        
        vm.startPrank(player3);
        bettingGame.placeCoinBet{value: 1 ether}(0); // Bet on heads
        vm.stopPrank();
        
        // Make player win
        randomWords[0] = 0; // heads - player wins
        mockVRFCoordinator.fulfillRandomWords(3, address(bettingGame), randomWords);
        
        uint256 finalPayout = (1 ether * 2 * 9800) / 10000; // 1.96 ETH
        console.log("Player 3 won %s ETH from 1 ETH bet", finalPayout / 1e18);
        console.log("House kept %s ETH as edge", (2 ether - finalPayout) / 1e18);
        console.log("Final contract balance: %s ETH", address(bettingGame).balance / 1e18);
        console.log("");
        
        // Summary
        console.log("=== LIQUIDITY POOL SUMMARY ===");
        console.log("- Lost wagers stay in contract and become available liquidity");
        console.log("- Winners get paid from the accumulated contract balance");
        console.log("- House edge (2%) permanently increases the liquidity pool");
        console.log("- This creates a sustainable betting system!");
        
        // Verify the math
        uint256 totalBetsPlaced = 0.5 ether + 0.3 ether + 1 ether; // 1.8 ETH
        uint256 totalPayouts = expectedPayout + finalPayout; // 0.588 + 1.96 = 2.548 ETH
        uint256 expectedFinalBalance = 2 ether + totalBetsPlaced - totalPayouts;
        
        assertEq(address(bettingGame).balance, expectedFinalBalance);
        console.log("VERIFIED: Math is correct - Contract balance matches expected!");
    }
}
