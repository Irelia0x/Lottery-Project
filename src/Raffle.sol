// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions2

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A Sample Raffle Contract
 * @author Amr Khaled
 * @notice creating simple raffle
 * @dev Implementing chainlink VRF2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {
    /** Errors  */
    error Raffle__SendMoreETHtoEnterRaffle();
    error Raffle__TransfereFailed();
    error Raffle_raffleNotOpen();
    error Raffle__UpKeepNotNeeded(uint256 balance, uint256 length, uint256 state);


    /**  Type declarations*/
    enum RaffleState{
        OPEN,               // 0
        CALCULATING         // 1 
    }


/** State variables */
    uint256 private immutable i_Entrance_Fee;
    // @dev the duration of the lottery in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    address private s_mostRecentWinner;
    RaffleState private s_rafflestate;


    /** Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed recentWinner);
    event RequestedRaffleWinner(uint indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
        
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_Entrance_Fee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_rafflestate = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        //require(msg.value >= i_Entrance_Fee, "Not Enough ETH Sent!");
        //require(msg.value >= i_Entrance_Fee, SendMoreETHtoEnterRaffle());
        if (msg.value < i_Entrance_Fee) {
            revert Raffle__SendMoreETHtoEnterRaffle();
        }
        if (s_rafflestate != RaffleState.OPEN){
            revert Raffle_raffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }



    // 1. Get a random number DONE
    // 2. use random number to pick a player DONE
    // 3. be autimatically called
    // 4.


// when the winner should be picked

/**
 * @dev This is the function that the chainlink nodes will call to see
 * if the lottery is ready ti have a winner picked
 * The following should be true in order to upkeepNeeded to be true:
 * 1. The time interval has passed between raffle runs
 * 2. The lottery is open
 * 3. The contract has ETH
 * 4. ur subscibtion has LINK
 * @param  - ignored
 * @return upkeepNeeded - true if its time to restart the lottery 
 * @return - ignored
 */

    function checkUpkeep(bytes memory /* checkData */) public view returns (
      bool upkeepNeeded,
      bytes memory /* performData */
    )
    {
         bool timeHasPassed =  ((block.timestamp - s_lastTimeStamp) >= i_interval);
         bool isOpen = s_rafflestate == RaffleState.OPEN;
         bool hasBalance = address(this).balance > 0;
         bool hasPlayers = s_players.length > 0;

         upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
         return (upkeepNeeded, "");
          }




    function performUpkeep(bytes calldata /* performData */) external  {
       (bool upkeepNeeded,) = checkUpkeep("");
       if (!upkeepNeeded){
        revert Raffle__UpKeepNotNeeded(address(this).balance, s_players.length, uint256(s_rafflestate));
       }

        s_rafflestate = RaffleState.CALCULATING;
      VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
        keyHash: i_keyHash, // Gas lane
        subId: i_subscriptionId,// how we fund the oracle gas for working for chainlink
        requestConfirmations: REQUEST_CONFIRMATION, //how many blocks we should wait to give random Number
        callbackGasLimit: i_callbackGasLimit,// limit of gas to use
        numWords: NUM_WORDS, // how many random numbers 
        extraArgs: VRFV2PlusClient._argsToBytes(
            VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
             // nativePayment: false means pay with LINK tokens
            //nativePayment: true would pay with native blockchain currency
            )
      });
    
    uint256 requestId = s_vrfCoordinator.requestRandomWords(request);

    emit RequestedRaffleWinner(requestId);
    }

function fulfillRandomWords(uint256 /*requestId*/, uint256[] calldata randomWords) internal override{
    // Checks
    // if conditions

    /**
     * The winner logic is:
     * 1. we get the random number from chainlink
     * we modulo the random number by the arrayofplayers length 
     * we get that new number and use it as an index to pick the winner from the array
     */

    //effects (Internal contract state )
    uint256 indexofWinner = randomWords[0] % s_players.length;
    address payable recentWinner = s_players[indexofWinner];
    s_mostRecentWinner = recentWinner;


    s_rafflestate = RaffleState.OPEN;
    s_players = new address payable[](0);
    s_lastTimeStamp = block.timestamp;
    emit WinnerPicked(recentWinner);


    // Interactions
    (bool success,) = recentWinner.call{value: address(this).balance}("");
    if (!success){
        revert Raffle__TransfereFailed();
    }


    }


    //**Getter functions */
    function getEntranceFee() public view returns (uint256) {
        return i_Entrance_Fee;
    }
    function getRaffleState() public view returns (RaffleState){
        return s_rafflestate;
    }
    function getplayer(uint256 indexOfPlayer) external view returns(address){
        return s_players[indexOfPlayer];
    }
    function getLastTimeStamp() external view returns (uint256){
        return s_lastTimeStamp;
    }
    function getRecentWinner() external view returns(address){
        return s_mostRecentWinner;
    }
}
