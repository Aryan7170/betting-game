// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {BettingGame} from "../src/BettingGame.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {MockVRFCoordinator} from "../test/mocks/MockVRFCoordinator.sol";
import {CodeConstants} from "./HelperConfig.s.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfigByChainId(block.chainid).vrfCoordinator;
        address account = helperConfig.getConfigByChainId(block.chainid).account;
        return createSubscription(vrfCoordinator, account);
    }

    function createSubscription(address vrfCoordinator, address account) public returns (uint64, address) {
        console.log("Creating subscription on chainId: ", block.chainid);
        vm.startBroadcast(account);
        uint64 subId = MockVRFCoordinator(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription Id is: ", subId);
        console.log("Please update the subscriptionId in HelperConfig.s.sol");
        return (subId, vrfCoordinator);
    }

    function run() external returns (uint64, address) {
        return createSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint64 subId, address account) public {
        console.log("Adding consumer contract: ", contractToAddToVrf);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
        vm.startBroadcast(account);
        MockVRFCoordinator(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint64 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;

        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId, account);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("BettingGame", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}

contract FundSubscription is CodeConstants, Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        uint64 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;

        if (subId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint64 updatedSubId, address updatedVRFv2) = createSub.run();
            subId = updatedSubId;
            vrfCoordinator = updatedVRFv2;
            console.log("New SubId Created! ", subId, "VRF Address: ", vrfCoordinator);
        }

        fundSubscription(vrfCoordinator, subId, account);
    }

    function fundSubscription(address vrfCoordinator, uint64 subId, address account) public {
        console.log("Funding subscription: ", subId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
        
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(account);
            MockVRFCoordinator(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            console.log("Please fund your subscription with LINK tokens manually");
            console.log("Subscription ID: ", subId);
            console.log("VRF Coordinator: ", vrfCoordinator);
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract PlaceBet is Script {
    function placeCoinBetUsingConfig(uint256 betAmount, uint256 prediction) public {
        HelperConfig helperConfig = new HelperConfig();
        address account = helperConfig.getConfig().account;
        
        address bettingGameAddress = vm.envAddress("BETTING_GAME_ADDRESS");
        
        placeCoinBet(bettingGameAddress, betAmount, prediction, account);
    }

    function placeCoinBet(address bettingGame, uint256 betAmount, uint256 prediction, address account) public {
        console.log("Placing coin bet on: ", bettingGame);
        console.log("Bet amount: ", betAmount);
        console.log("Prediction: ", prediction == 0 ? "Heads" : "Tails");
        
        vm.startBroadcast(account);
        BettingGame(payable(bettingGame)).placeCoinBet{value: betAmount}(prediction);
        vm.stopBroadcast();
    }

    function run() external {
        placeCoinBetUsingConfig(0.01 ether, 0); // Default: 0.01 ETH on heads
    }
}

contract PlaceDiceBet is Script {
    function placeDiceBetUsingConfig(uint256 betAmount, uint256 prediction) public {
        HelperConfig helperConfig = new HelperConfig();
        address account = helperConfig.getConfig().account;
        
        address bettingGameAddress = vm.envAddress("BETTING_GAME_ADDRESS");
        
        placeDiceBet(bettingGameAddress, betAmount, prediction, account);
    }

    function placeDiceBet(address bettingGame, uint256 betAmount, uint256 prediction, address account) public {
        console.log("Placing dice bet on: ", bettingGame);
        console.log("Bet amount: ", betAmount);
        console.log("Prediction: ", prediction);
        
        vm.startBroadcast(account);
        BettingGame(payable(bettingGame)).placeDiceBet{value: betAmount}(prediction);
        vm.stopBroadcast();
    }

    function run() external {
        placeDiceBetUsingConfig(0.01 ether, 4); // Default: 0.01 ETH on 4
    }
}

contract FulfillRandomWords is Script {
    function fulfillRandomWordsUsingConfig(uint256 requestId, uint256 randomness) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;
        
        address bettingGameAddress = vm.envAddress("BETTING_GAME_ADDRESS");
        
        fulfillRandomWords(requestId, randomness, vrfCoordinator, bettingGameAddress, account);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256 randomness,
        address vrfCoordinator,
        address consumer,
        address account
    ) public {
        console.log("Fulfilling random words for request: ", requestId);
        console.log("With randomness: ", randomness);
        console.log("VRF Coordinator: ", vrfCoordinator);
        console.log("Consumer: ", consumer);
        
        vm.startBroadcast(account);
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = randomness;
        MockVRFCoordinator(vrfCoordinator).fulfillRandomWords(requestId, consumer, randomWords);
        vm.stopBroadcast();
    }

    function run() external {
        fulfillRandomWordsUsingConfig(1, 12345); // Default values
    }
}
