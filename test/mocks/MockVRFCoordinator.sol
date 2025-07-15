// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract MockVRFCoordinator is VRFCoordinatorV2Interface {
    uint256 private s_requestId = 1;
    uint64 private s_subscriptionId = 1;
    mapping(uint256 => bool) private s_pendingRequests;
    mapping(uint64 => address[]) private s_consumers;
    mapping(uint64 => uint96) private s_balances;
    
    function requestRandomWords(
        bytes32, // keyHash
        uint64, // subId
        uint16, // minimumRequestConfirmations
        uint32, // callbackGasLimit
        uint32 // numWords
    ) external override returns (uint256 requestId) {
        requestId = s_requestId++;
        s_pendingRequests[requestId] = true;
        return requestId;
    }
    
    function fulfillRandomWords(
        uint256 requestId,
        address consumer,
        uint256[] memory randomWords
    ) external {
        require(s_pendingRequests[requestId], "Request not found");
        delete s_pendingRequests[requestId];
        
        VRFConsumerBaseV2(consumer).rawFulfillRandomWords(requestId, randomWords);
    }
    
    function getLastRequestId() external view returns (uint256) {
        return s_requestId - 1;
    }
    
    // Required interface implementations (not used in tests)
    function getRequestConfig() external pure override returns (uint16, uint32, bytes32[] memory) {
        return (0, 0, new bytes32[](0));
    }
    
    function createSubscription() external override returns (uint64) {
        return s_subscriptionId++;
    }
    
    function getSubscription(uint64) external pure override returns (uint96, uint64, address, address[] memory) {
        return (0, 0, address(0), new address[](0));
    }
    
    function requestSubscriptionOwnerTransfer(uint64, address) external pure override {
        // Not implemented for testing
    }
    
    function acceptSubscriptionOwnerTransfer(uint64) external pure override {
        // Not implemented for testing
    }
    
    function addConsumer(uint64 subId, address consumer) external override {
        s_consumers[subId].push(consumer);
    }
    
    function removeConsumer(uint64, address) external pure override {
        // Not implemented for testing
    }
    
    function cancelSubscription(uint64, address) external pure override {
        // Not implemented for testing
    }
    
    function pendingRequestExists(uint64) external pure override returns (bool) {
        return false;
    }
    
    function fundSubscription(uint64 subId, uint96 amount) external {
        s_balances[subId] += amount;
    }
}
