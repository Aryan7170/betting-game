// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../test/mocks/MockVRFCoordinator.sol";

/**
 * @title HelperConfig
 * @dev Configuration helper for different networks
 */
contract HelperConfig is Script {
    
    struct NetworkConfig {
        uint64 subscriptionId;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        uint256 deployerKey;
        string networkName;
        bool needsMockVRF;
    }
    
    uint256 public constant DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    
    NetworkConfig public activeNetworkConfig;
    
    mapping(uint256 => NetworkConfig) public networkConfigs;
    
    constructor() {
        // Initialize network configurations
        setupNetworkConfigs();
        
        // Set active config based on current chain
        activeNetworkConfig = getConfigByChainId(block.chainid);
    }
    
    function setupNetworkConfigs() internal {
        // Anvil / Local Network (Chain ID: 31337)
        networkConfigs[31337] = NetworkConfig({
            subscriptionId: 1,
            vrfCoordinator: address(0), // Will be set to mock during deployment
            gasLane: bytes32(uint256(1)),
            callbackGasLimit: getCallbackGasLimitOrDefault(),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY,
            networkName: "Anvil Local",
            needsMockVRF: true
        });
        
        // Sepolia Testnet (Chain ID: 11155111)
        networkConfigs[11155111] = NetworkConfig({
            subscriptionId: getSubscriptionIdOrDefault(),
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // 30 gwei
            callbackGasLimit: getCallbackGasLimitOrDefault(),
            deployerKey: getPrivateKeyOrDefault(),
            networkName: "Sepolia Testnet",
            needsMockVRF: false
        });
        
        // Ethereum Mainnet (Chain ID: 1)
        networkConfigs[1] = NetworkConfig({
            subscriptionId: getSubscriptionIdOrDefault(),
            vrfCoordinator: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
            gasLane: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef, // 200 gwei
            callbackGasLimit: getCallbackGasLimitOrDefault(),
            deployerKey: getPrivateKeyOrDefault(),
            networkName: "Ethereum Mainnet",
            needsMockVRF: false
        });
        
        // Polygon Mainnet (Chain ID: 137)
        networkConfigs[137] = NetworkConfig({
            subscriptionId: getSubscriptionIdOrDefault(),
            vrfCoordinator: 0xAE975071Be8F8eE67addBC1A82488F1C24858067,
            gasLane: 0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93, // 500 gwei
            callbackGasLimit: getCallbackGasLimitOrDefault(),
            deployerKey: getPrivateKeyOrDefault(),
            networkName: "Polygon Mainnet",
            needsMockVRF: false
        });
        
        // Arbitrum One (Chain ID: 42161)
        networkConfigs[42161] = NetworkConfig({
            subscriptionId: getSubscriptionIdOrDefault(),
            vrfCoordinator: 0x41034678D6C633D8a95c75e1138A360a28bA15d1,
            gasLane: 0x68d24f9a037a649944964c2a1ebd0b2918f4a243d2a99701cc22b548cf2daff0, // 150 gwei
            callbackGasLimit: getCallbackGasLimitOrDefault(),
            deployerKey: getPrivateKeyOrDefault(),
            networkName: "Arbitrum One",
            needsMockVRF: false
        });
    }
    
    function getSubscriptionIdOrDefault() internal view returns (uint64) {
        // Try to get VRF_SUBSCRIPTION_ID from environment, fall back to 1 (will fail validation)
        try vm.envUint("VRF_SUBSCRIPTION_ID") returns (uint256 subId) {
            return uint64(subId);
        } catch {
            return 1; // Default value - deployment will warn about this
        }
    }
    
    function getCallbackGasLimitOrDefault() internal view returns (uint32) {
        // Try to get VRF_CALLBACK_GAS_LIMIT from environment, fall back to 300000
        try vm.envUint("VRF_CALLBACK_GAS_LIMIT") returns (uint256 gasLimit) {
            return uint32(gasLimit);
        } catch {
            return 300000; // Default value
        }
    }
    
    function getPrivateKeyOrDefault() internal view returns (uint256) {
        // Try to get PRIVATE_KEY from environment, fall back to default anvil key
        try vm.envUint("PRIVATE_KEY") returns (uint256 key) {
            return key;
        } catch {
            return DEFAULT_ANVIL_PRIVATE_KEY;
        }
    }
    
    function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0) || networkConfigs[chainId].needsMockVRF) {
            return networkConfigs[chainId];
        } else {
            // Default to Anvil config for unknown networks
            return networkConfigs[31337];
        }
    }
    
    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }
    
    function getNetworkName() public view returns (string memory) {
        return activeNetworkConfig.networkName;
    }
    
    function isLocalNetwork() public view returns (bool) {
        return block.chainid == 31337;
    }
    
    function needsMockVRF() public view returns (bool) {
        return activeNetworkConfig.needsMockVRF;
    }
    
    function deployMockVRF() public returns (MockVRFCoordinator) {
        if (!needsMockVRF()) {
            revert("Mock VRF not needed for this network");
        }
        
        vm.startBroadcast(activeNetworkConfig.deployerKey);
        MockVRFCoordinator mockVRFCoordinator = new MockVRFCoordinator();
        vm.stopBroadcast();
        
        return mockVRFCoordinator;
    }
    
    function updateNetworkConfig(uint256 chainId, NetworkConfig memory config) public {
        networkConfigs[chainId] = config;
        if (chainId == block.chainid) {
            activeNetworkConfig = config;
        }
    }
    
    function getChainlinkVRFDocumentation() public view returns (string memory) {
        if (isLocalNetwork()) {
            return "Local network - using MockVRFCoordinator";
        } else {
            return "Visit https://docs.chain.link/vrf/v2/subscription/supported-networks for VRF configuration";
        }
    }
    
    function getDeploymentInstructions() public view returns (string memory) {
        if (isLocalNetwork()) {
            return "Ready for local testing! MockVRFCoordinator will be deployed automatically.";
        } else {
            return string(abi.encodePacked(
                "1. Create VRF subscription at https://vrf.chain.link/ \n",
                "2. Fund subscription with LINK tokens \n",
                "3. Update subscriptionId in HelperConfig \n",
                "4. Deploy contract \n",
                "5. Add deployed contract as VRF consumer"
            ));
        }
    }
    
    function validateConfig() public view returns (bool) {
        NetworkConfig memory config = activeNetworkConfig;
        
        // Basic validation
        if (config.callbackGasLimit == 0) return false;
        if (config.gasLane == bytes32(0)) return false;
        if (config.deployerKey == 0) return false;
        
        // VRF Coordinator validation
        if (config.needsMockVRF) {
            // For mock, we don't need real VRF coordinator
            return true;
        } else {
            // For real networks, we need valid VRF coordinator
            if (config.vrfCoordinator == address(0)) return false;
            // Warn if subscription ID is default (1)
            if (config.subscriptionId == 1) {
                console.log("WARNING: Using default subscription ID (1)");
                console.log("Please set VRF_SUBSCRIPTION_ID environment variable");
                console.log("Get your subscription ID from https://vrf.chain.link/");
            }
            
            // Warn if callback gas limit is default and not set in environment
            try vm.envUint("VRF_CALLBACK_GAS_LIMIT") returns (uint256) {
                // Environment variable is set, no warning needed
            } catch {
                console.log("INFO: Using default callback gas limit (300000)");
                console.log("Set VRF_CALLBACK_GAS_LIMIT environment variable to customize");
            }
        }
        
        return true;
    }
}
