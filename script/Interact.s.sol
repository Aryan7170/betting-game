// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/BettingGame.sol";
import "./HelperConfig.s.sol";

contract Interact is Script {
    
    function run() external {
        address bettingGameAddress = vm.envAddress("BETTING_GAME_ADDRESS");
        
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();
        
        BettingGame bettingGame = BettingGame(payable(bettingGameAddress));
        
        vm.startBroadcast(config.deployerKey);
        
        console.log("=== Placing Coin Bet ===");
        console.log("Betting 0.01 ETH on heads (0)...");
        bettingGame.placeCoinBet{value: 0.01 ether}(0);
        
        console.log("=== Placing Dice Bet ===");
        console.log("Betting 0.01 ETH on rolling a 4...");
        bettingGame.placeDiceBet{value: 0.01 ether}(4);
        
        vm.stopBroadcast();
        
        console.log("=== CONTRACT STATE ===");
        console.log("Network:", config.networkName);
        console.log("Contract balance:", address(bettingGame).balance, "wei");
        console.log("Total bets placed:", bettingGame.totalBets());
        console.log("Total payouts:", bettingGame.totalPayout());
        console.log("Next bet ID:", bettingGame.nextBetId());
        
        uint256[] memory playerBets = bettingGame.getPlayerBets(vm.addr(config.deployerKey));
        console.log("=== PLAYER BETS ===");
        console.log("Player:", vm.addr(config.deployerKey));
        console.log("Total bets:", playerBets.length);
        
        if (helperConfig.isLocalNetwork()) {
            console.log("=== LOCAL TESTING INSTRUCTIONS ===");
            console.log("To fulfill VRF requests manually:");
            console.log("cast send", config.vrfCoordinator, "\"fulfillRandomWords(uint256,uint256)\" <requestId> <randomness>");
        }
    }
}
