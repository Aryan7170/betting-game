// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/BettingGame.sol";
import "./HelperConfig.s.sol";

/**
 * @title Deploy
 * @dev Unified deployment script for all networks using HelperConfig
 * 
 * Usage:
 * 1. Environment variables (recommended): forge script script/Deploy.s.sol
 * 2. Direct parameters: forge script script/Deploy.s.sol --sig "run(uint64,uint256)" <subscriptionId> <fundingAmount>
 */
contract Deploy is Script {
    
    function run() external {
        _deploy(0, 0); // Use environment variables
    }
    
    function run(uint64 subscriptionId, uint256 fundingAmount) external {
        _deploy(subscriptionId, fundingAmount); // Use provided parameters
    }
    
    function _deploy(uint64 subscriptionIdOverride, uint256 fundingAmountOverride) internal {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getActiveNetworkConfig();
        
        // Override subscription ID if provided as parameter
        if (subscriptionIdOverride != 0) {
            config.subscriptionId = subscriptionIdOverride;
            console.log("Using subscription ID from parameter:", subscriptionIdOverride);
        }
        
        // Validate configuration
        require(helperConfig.validateConfig(), "Invalid network configuration");
        
        // Log funding information
        logFundingInfo(fundingAmountOverride);
        
        address vrfCoordinator = config.vrfCoordinator;
        
        // Deploy mock VRF coordinator if needed
        if (config.needsMockVRF) {
            console.log("Deploying MockVRFCoordinator for local testing...");
            MockVRFCoordinator mockVRF = helperConfig.deployMockVRF();
            vrfCoordinator = address(mockVRF);
            console.log("MockVRFCoordinator deployed at:", vrfCoordinator);
        }
        
        // Deploy BettingGame
        vm.startBroadcast(config.deployerKey);
        
        BettingGame bettingGame = new BettingGame(
            config.subscriptionId,
            vrfCoordinator,
            config.gasLane,
            config.callbackGasLimit
        );
        
        // Fund contract based on parameters or environment
        uint256 fundingAmount = getFundingAmount(fundingAmountOverride);
        if (fundingAmount > 0) {
            console.log("Funding contract with", fundingAmount, "wei...");
            (bool success, ) = address(bettingGame).call{value: fundingAmount}("");
            require(success, "Failed to fund contract");
        } else if (helperConfig.isLocalNetwork()) {
            // Default funding for local testing (5 ETH)
            uint256 defaultFunding = 5 ether;
            console.log("Funding contract with", defaultFunding, "wei for local testing...");
            (bool success, ) = address(bettingGame).call{value: defaultFunding}("");
            require(success, "Failed to fund contract");
        }
        
        vm.stopBroadcast();
        
        // Display deployment information
        displayDeploymentInfo(bettingGame, config, vrfCoordinator);
        
        // Show next steps
        console.log("\n=== NEXT STEPS ===");
        console.log(helperConfig.getDeploymentInstructions());
    }
    
    function getFundingAmount(uint256 fundingAmountOverride) internal view returns (uint256) {
        // If override is provided, use it
        if (fundingAmountOverride > 0) {
            return fundingAmountOverride;
        }
        
        // Otherwise try to get from environment
        try vm.envUint("INITIAL_FUNDING") returns (uint256 funding) {
            return funding;
        } catch {
            return 0; // No funding specified
        }
    }
    
    function logFundingInfo(uint256 fundingAmountOverride) internal view {
        uint256 funding = getFundingAmount(fundingAmountOverride);
        if (funding > 0) {
            if (fundingAmountOverride > 0) {
                console.log("INFO: Contract will be funded with", funding, "wei (from parameter)");
            } else {
                console.log("INFO: Contract will be funded with", funding, "wei (from INITIAL_FUNDING)");
            }
        } else {
            console.log("INFO: No funding specified, contract will not be funded during deployment");
            console.log("      For local testing, contract will be funded with 5 ETH by default");
        }
    }
    
    function displayDeploymentInfo(
        BettingGame bettingGame,
        HelperConfig.NetworkConfig memory config,
        address vrfCoordinator
    ) internal view {
        console.log("\n=== DEPLOYMENT SUCCESSFUL ===");
        console.log("Network:", config.networkName);
        console.log("Chain ID:", block.chainid);
        console.log("Deployer:", vm.addr(config.deployerKey));
        console.log("BettingGame:", address(bettingGame));
        console.log("VRF Coordinator:", vrfCoordinator);
        console.log("Subscription ID:", config.subscriptionId);
        console.log("Gas Lane:", vm.toString(config.gasLane));
        console.log("Callback Gas Limit:", config.callbackGasLimit);
        
        console.log("\n=== CONTRACT INFO ===");
        console.log("Owner:", bettingGame.owner());
        console.log("Min bet:", bettingGame.MIN_BET(), "wei");
        console.log("Max bet:", bettingGame.MAX_BET(), "wei");
        console.log("House edge:", bettingGame.HOUSE_EDGE(), "basis points (2%)");
        console.log("Contract balance:", address(bettingGame).balance, "wei");
        
        if (config.needsMockVRF) {
            console.log("\n=== LOCAL TESTING READY ===");
            console.log("Mock VRF is deployed and ready for testing!");
            console.log("You can now place bets and test the contract locally.");
        } else {
            console.log("\n=== TESTNET/MAINNET DEPLOYMENT ===");
            console.log("Remember to:");
            console.log("1. Fund your VRF subscription with LINK tokens");
            console.log("2. Add this contract as a VRF consumer");
            console.log("3. Fund the contract with ETH for payouts");
        }
    }
}
