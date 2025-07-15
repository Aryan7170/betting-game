// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {BettingGame} from "../src/BettingGame.sol";
import {AddConsumer, CreateSubscription, FundSubscription} from "./Interactions.s.sol";

contract DeployBettingGame is Script {
    function run() external returns (BettingGame, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // This comes with our mocks!
        AddConsumer addConsumer = new AddConsumer();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        
        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = 
                createSubscription.createSubscription(config.vrfCoordinator, config.account);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinator, config.subscriptionId, config.account
            );

            helperConfig.setConfig(block.chainid, config);
        }

        vm.startBroadcast(config.account);
        BettingGame bettingGame = new BettingGame(
            config.subscriptionId,
            config.vrfCoordinator,
            config.gasLane,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        // We already have a broadcast in here
        addConsumer.addConsumer(address(bettingGame), config.vrfCoordinator, config.subscriptionId, config.account);
        return (bettingGame, helperConfig);
    }
}