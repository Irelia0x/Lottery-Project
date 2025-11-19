//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";

contract RaffleTest is Test, CodeConstants {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;
        event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed recentWinner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run(); // Changed from deployContract() to run()
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        
    }

    // Modifiers
    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
       _; 
    }
    modifier skipFork(){
        if(block.chainid != LOCAL_CHAIN_ID){
            return;
        }
        _;
    }


    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
    function testRaffleRevertsWhenUdontpayenough()public  {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__SendMoreETHtoEnterRaffle.selector);
        raffle.enterRaffle();
    }
    function testRaffleRecordsPlayersWhenTheyEnter() public {
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    address playerRecorded = raffle.getplayer(0);
    assert(playerRecorded == PLAYER);
    
    }

    function testEnteringRaffleEmitEvent() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false,address(raffle));
        emit RaffleEntered(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
    function testDontallowplayerstoEnterwhileraffleisCalculating()public raffleEntered{
        
   
        raffle.performUpkeep("");
        // now rafflestate should be calculating 
        vm.expectRevert(Raffle.Raffle_raffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
    function testCheckupkeepreturnsfalseifithasnobalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, )= raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }
    function testCheclupkeepreturnsfalseifRaffleisclosed() public raffleEntered{
        
        raffle.performUpkeep("");

        (bool upkeepNeeded, )= raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }
    function testCheckupkeepReturnsFalseIfEnoughTimeHasPassed () public raffleEntered{
      
        raffle.performUpkeep("");

        (bool upkeepNeeded, )= raffle.checkUpkeep("");
        assert(!upkeepNeeded);

    }

    function testCheckUpkeepReturnsTrueWhenParametersGood() public raffleEntered{
        // Arrange
        

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assert(upkeepNeeded);
    }
    function testPerformUpKeepCanOnlyRunIfCheckUpKeepIsTrue()public raffleEntered{
       
        raffle.performUpkeep("");
    }

    function testPerfomUpKeepRevertsIfCheckUpkeepisFalse()public {
         uint256 currentBalance = 0;
         uint256 numPlayers = 0;
         Raffle.RaffleState rState = raffle.getRaffleState();

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();     
        currentBalance = currentBalance + entranceFee;
        numPlayers = 1;

         vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpKeepNotNeeded.selector, currentBalance,numPlayers, rState )
         );
         raffle.performUpkeep("");
    }


    function testPerfomrUpKeepUpdatedRaffleStateAndEmitsRequestId() public raffleEntered {
      
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    // stateless fuzz test
    function testFulfilrandomwordsCanOnlyBeCalledAfterPerformUpKeep(uint256 randomRequestId) 
    public raffleEntered skipFork {
        // Arrange / Act /assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }


    //E2E test 
    function testFulfilrandomwordsPicksAWinnerResetsAndSendMoney()
     public raffleEntered skipFork{
        // Arrange

        
        uint256 additionalEntrance = 3; //4people total to enter
        uint256 startingIndex = 1;
        address expectedWinner = address(1);

        for(uint256 i = startingIndex; i < startingIndex + additionalEntrance; i++){
            address newPlayer = address(uint160(i)); //address(1)
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: entranceFee}();  
            }
        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 winnerStartingBalance = expectedWinner.balance;

        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        // Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endngTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee *(additionalEntrance +1);

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0 );
        assert(winnerBalance == winnerStartingBalance + prize);
        assert(endngTimeStamp > startingTimeStamp);


    }
   
}