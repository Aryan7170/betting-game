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
            (config.subscriptionId, config.vrfCoordinatorV2_5) =
                createSubscription.createSubscription(config.vrfCoordinatorV2_5, config.account);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinatorV2_5, config.subscriptionId, config.link, config.account
            );

            helperConfig.setConfig(block.chainid, config);
        }

        vm.startBroadcast(config.account);
        BettingGame bettingGame = new BettingGame(
            config.subscriptionId,
            config.vrfCoordinatorV2_5,
            config.gasLane,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        // We already have a broadcast in here
        addConsumer.addConsumer(address(bettingGame), config.vrfCoordinatorV2_5, config.subscriptionId, config.account);
        return (bettingGame, helperConfig);
    }
}
