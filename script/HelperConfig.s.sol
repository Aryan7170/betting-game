// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {MockVRFCoordinator} from "../test/mocks/MockVRFCoordinator.sol";

abstract contract CodeConstants {
    /*//////////////////////////////////////////////////////////////
                               CHAIN IDS
    //////////////////////////////////////////////////////////////*/
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant POLYGON_MAINNET_CHAIN_ID = 137;
    uint256 public constant ARBITRUM_MAINNET_CHAIN_ID = 42161;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    /*//////////////////////////////////////////////////////////////
                            DEFAULT VALUES
    //////////////////////////////////////////////////////////////*/
    uint32 public constant DEFAULT_CALLBACK_GAS_LIMIT = 300000;
    uint64 public constant DEFAULT_SUBSCRIPTION_ID = 0;
    
    address public constant FOUNDRY_DEFAULT_SENDER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
}

contract HelperConfig is CodeConstants, Script {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error HelperConfig__InvalidChainId();

    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/
    struct NetworkConfig {
        uint64 subscriptionId;
        address vrfCoordinator;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        address account;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        networkConfigs[ETH_MAINNET_CHAIN_ID] = getMainnetEthConfig();
        networkConfigs[POLYGON_MAINNET_CHAIN_ID] = getPolygonMainnetConfig();
        networkConfigs[ARBITRUM_MAINNET_CHAIN_ID] = getArbitrumMainnetConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function setConfig(uint256 chainId, NetworkConfig memory networkConfig) public {
        networkConfigs[chainId] = networkConfig;
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    /*//////////////////////////////////////////////////////////////
                                CONFIGS
    //////////////////////////////////////////////////////////////*/
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            subscriptionId: DEFAULT_SUBSCRIPTION_ID, // If left as 0, our scripts will create one!
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            callbackGasLimit: DEFAULT_CALLBACK_GAS_LIMIT,
            account: FOUNDRY_DEFAULT_SENDER
        });
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory mainnetNetworkConfig) {
        mainnetNetworkConfig = NetworkConfig({
            subscriptionId: DEFAULT_SUBSCRIPTION_ID, // If left as 0, our scripts will create one!
            vrfCoordinator: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
            gasLane: 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805,
            callbackGasLimit: DEFAULT_CALLBACK_GAS_LIMIT,
            account: FOUNDRY_DEFAULT_SENDER
        });
    }

    function getPolygonMainnetConfig() public pure returns (NetworkConfig memory polygonNetworkConfig) {
        polygonNetworkConfig = NetworkConfig({
            subscriptionId: DEFAULT_SUBSCRIPTION_ID, // If left as 0, our scripts will create one!
            vrfCoordinator: 0xAE975071Be8F8eE67addBC1A82488F1C24858067,
            gasLane: 0x6e099d640cde6de9d40ac749b4b594126b0169747122711109c9985d47751f93,
            callbackGasLimit: DEFAULT_CALLBACK_GAS_LIMIT,
            account: FOUNDRY_DEFAULT_SENDER
        });
    }

    function getArbitrumMainnetConfig() public pure returns (NetworkConfig memory arbitrumNetworkConfig) {
        arbitrumNetworkConfig = NetworkConfig({
            subscriptionId: DEFAULT_SUBSCRIPTION_ID, // If left as 0, our scripts will create one!
            vrfCoordinator: 0x41034678D6C633D8a95c75e1138A360a28bA15d1,
            gasLane: 0x68d24f9a037a649944964c2a1ebd0b2918f4a243d2a99701cc22b548cf2daff0,
            callbackGasLimit: DEFAULT_CALLBACK_GAS_LIMIT,
            account: FOUNDRY_DEFAULT_SENDER
        });
    }

    /*//////////////////////////////////////////////////////////////
                              LOCAL CONFIG
    //////////////////////////////////////////////////////////////*/
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // Check to see if we set an active network config
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        console2.log(unicode"⚠️ You have deployed a mock contract!");
        console2.log("Make sure this was intentional");
        
        vm.startBroadcast();
        MockVRFCoordinator mockVRFCoordinator = new MockVRFCoordinator();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            subscriptionId: 1, // Mock subscription ID
            vrfCoordinator: address(mockVRFCoordinator),
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // doesn't really matter
            callbackGasLimit: DEFAULT_CALLBACK_GAS_LIMIT,
            account: FOUNDRY_DEFAULT_SENDER
        });
        
        vm.deal(localNetworkConfig.account, 100 ether);
        return localNetworkConfig;
    }
}
