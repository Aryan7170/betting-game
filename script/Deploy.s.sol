// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {BettingGame} from "../src/BettingGame.sol";

contract Deploy is Script {
    function run() external returns (BettingGame) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        BettingGame bettingGame = new BettingGame(
            config.subscriptionId,
            config.vrfCoordinatorV2_5,
            config.gasLane,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        console.log("BettingGame deployed at:", address(bettingGame));
        console.log("VRF Coordinator:", config.vrfCoordinatorV2_5);
        console.log("Subscription ID:", config.subscriptionId);
        console.log("Gas Lane:", vm.toString(config.gasLane));
        console.log("Callback Gas Limit:", config.callbackGasLimit);

        return bettingGame;
    }
}
