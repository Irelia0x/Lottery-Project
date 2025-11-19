//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
error HelperConfig__InvalidChainId();

abstract contract CodeConstants {
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is Script, CodeConstants {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        address account;
    }

    NetworkConfig public activeNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaEthConfig();
            networkConfigs[ETH_SEPOLIA_CHAIN_ID] = activeNetworkConfig;
        } else {
            networkConfigs[LOCAL_CHAIN_ID] = activeNetworkConfig;
        }
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

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 55230028568293925324538249236496294959803159128106589322967001756052175710834, 
            callbackGasLimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0xa6f08aBa1D69B1fc9092e8Bc348dA5744B01E955
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // If we already have a config, return it
         if (networkConfigs[LOCAL_CHAIN_ID].vrfCoordinator != address(0)) {
            activeNetworkConfig = networkConfigs[LOCAL_CHAIN_ID];
            return activeNetworkConfig;
        }

        // Deploy mocks
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE, 
            MOCK_GAS_PRICE_LINK, 
            MOCK_WEI_PER_UINT_LINK
        );
        LinkToken link = new LinkToken();
        
        // Create a subscription on the mock 
        uint256 subId = vrfCoordinatorMock.createSubscription();       
        NetworkConfig memory anvilConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: subId, // Use the actual subscription ID from mock
            callbackGasLimit: 500000,
            link: address(link),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        });

        // Update both activeNetworkConfig and the mapping
        activeNetworkConfig = anvilConfig;
        networkConfigs[LOCAL_CHAIN_ID] = anvilConfig;

        vm.stopBroadcast();
        return anvilConfig;
    }
}