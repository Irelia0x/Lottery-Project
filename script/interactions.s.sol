//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {

    function run() public {}

    function CreateSubscriptionUsingConfig()public  returns(uint256, address){
        HelperConfig helperConfig = new HelperConfig();
       address vrfCoordinator =  helperConfig.getConfig().vrfCoordinator;
       address account = helperConfig.getConfig().account;
       (uint256 subId ,) = createSubscription(vrfCoordinator, account);
        return(subId, vrfCoordinator);

    }

    function createSubscription(address vrfCoordinator, address account) public returns(uint256, address){
        console.log("creating subscription on chain Id: ", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("subscription ID is:", subId);
        console.log("Please Update it in Helperconfig");
        return(subId, vrfCoordinator);

    }

}

contract FundSubscription is Script, CodeConstants { // literally funded my account
// on chainlink with the value i set here FUND_AMOUNT 
    uint256 public constant FUND_AMOUNT = 3 ether;// 3 LINK
    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
       address vrfCoordinator =  helperConfig.getConfig().vrfCoordinator;
       uint256 subscriptionId =  helperConfig.getConfig().subscriptionId;
       address linkToken = helperConfig.getConfig().link;
       address account = helperConfig.getConfig().account;
       fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);

    }
    function fundSubscription(address vrfCoordinator, uint256 subscriptionId,
     address linkToken, address account) public 
    {
        console.log("Funded subscription ID:", subscriptionId);
        console.log("using vrfCoordinator: ", vrfCoordinator);
        console.log("On Chain Id: ", block.chainid);
        if (block.chainid == LOCAL_CHAIN_ID){
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT*100);
            vm.stopBroadcast(); 
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT,
            abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
   
    }


    function run() public{
        fundSubscriptionUsingConfig();}
}

contract AddConsumer is Script{

    function addConsumerUsingconfig(address mostRecentlyDeployed )public {
         HelperConfig helperConfig = new HelperConfig();
         uint subId = helperConfig.getConfig().subscriptionId;
         address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
         address account = helperConfig.getConfig().account;
         addConsumer(mostRecentlyDeployed, vrfCoordinator, subId, account);
 
    }
    function addConsumer(address contractToaddVrf,
     address vrfCoordinator,uint256 subId, address account) public{
        console.log("adding consumer to contract: ", contractToaddVrf);
        console.log("TO vrfCoordinator", vrfCoordinator);
        console.log("On chainId: ", block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToaddVrf);
        vm.stopBroadcast();

    }
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingconfig(mostRecentlyDeployed);

    }
}