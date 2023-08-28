// SPDX-License-Identifier: CC-BY-SA 4.0
//https://creativecommons.org/licenses/by-sa/4.0/

// TL;DR: The creator of this contract (@LogETH) is not liable for any damages associated with using the following code
// This contract must be deployed with credits toward the original creator, @LogETH.
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests I endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the license.

// By deploying this contract, you agree to the license above and the terms and conditions that come with it.

pragma solidity >=0.8.0 <0.9.0;


contract RepeatingLotteryReferral{

//// This contract is a referral system for a lottery that repeats itself

    // Instructions on how to setup the contract:
    // https://docs.google.com/document/d/1dA6kW0114xwe_flailso4VwDyUrCXknFjhqKydbBT5U/edit

//// Commissioned by someone on 8/18/2023

    // the constructor that activates when you deploy the contract, this is where you change settings before deploying.

    constructor(){

        USDT = ERC20(0x2e1F920a4C157BD89606792081f73C6439548817); // What token this contract uses
        admin = msg.sender;

        raffleDuration = 3 days; // How long the raffle should take

        //// Chainlink variables, chainlink should tell you what to put here when you make a subscription, the values here are for sepolia testnet.

        s_subscriptionId = 4736;
        vrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
        s_keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    }


//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////



//// Special Variables go here:

    ERC20 USDT;

//// All the Variables that this contract uses

    uint public raffleNonce; // What number raffle we are on, starts at 0, you can use previous numbers to look up data about previous raffles

    mapping(uint => mapping (address => bool)) public hasContributed; // Who has contributed to the raffle
    mapping(uint => mapping (uint => address)) public list;           // List of addresses in the raffle
    mapping(uint => address) public winner;                           // The winners of the raffles
    mapping(uint => uint) public endTime;                             // The time the raffle's winner is drawn
    mapping(uint => uint) internalPot;                                // The current pot with fees added
    mapping(address => bool) raffleContract;


    uint public raffleDuration;                                 // How long the raffle lasts for
    address public admin;                                       // The address that is allowed to use admin functions
    uint public nonce;                                          // How many contributions the current raffle has received, starts at 0 so add 1 to get the true amount.
    uint public cost;                                           // How much it costs to contribute to the pot
    bool open;                                                  // Is the raffle initalized?
    bool limited;                                               // Whether the raffle allows for multiple entries or not.
    bool rolling;                                               // If the winner is currently being drawn, prevents the contract from accedentally drawing twice.
    uint refMultiplier;                                         // How many entries into the referral pot should one referral give?
    

    
//// Modifiers

    modifier requireNotRolling  {require(!rolling,              "Cannot use while rolling");_;}
    modifier onlyAdmin          {require(msg.sender == admin,   "Not Authorized");_;}
    modifier requireOpen        {require(open,                  "Not Open");_;}
    modifier requireClosed      {require(!open,                 "Not Closed");_;}


//// Chainlink variables 

    uint64 s_subscriptionId;
    address vrfCoordinator;
    bytes32 s_keyHash;
    uint32 public callbackGasLimit = 200000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;

//// Events

    event Contribution(address indexed _contributor, uint _numTimes);
    event WinnerDrawn(address indexed _winner, uint _amtReceived, uint numOfContributions);

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


//// Put visible functions (Buttons that people press) here:

    // Begins the raffle

    function initializeRaffle() public onlyAdmin requireClosed{

        endTime[raffleNonce] = block.timestamp + raffleDuration;
        open = true;
        
    }

    function setRaffleContractAddress(address _raffleContract, bool trueOrFalse) public onlyAdmin{

        raffleContract[_raffleContract] = trueOrFalse;
    }

    function changeCallbackGasLimit(uint32 howmuch) public onlyAdmin{

        callbackGasLimit = howmuch;
    }

    // Lets someone contribute, put 0x00...000 for no referral address.

    function enterReferral(address referralAddress, uint HowManyTimes) public requireOpen requireNotRolling{

        require(HowManyTimes != 0, "Cannot be zero");
        require(raffleContract[msg.sender], "Not Authorized");

        // enter the referralAddress into the raffle as many times as they are eligible for.

        for(uint i; i < HowManyTimes; i++){

            list[raffleNonce][nonce] = referralAddress;                       // List the msg.sender as a contributor
            nonce++;                                                          // move up the list by one
        }

        emit Contribution(referralAddress, HowManyTimes);
    }

    function drawWinner() public requireOpen requireNotRolling{

        require(block.timestamp > endTime[raffleNonce], "The raffle has not ended yet");

        //// If there are no contributions, restart the raffle

        if(nonce == 0){

            raffleNonce ++;
            nonce = 0;
            endTime[raffleNonce] = block.timestamp + raffleDuration;
            rolling = false;

            return;
        }

        //// rolling bool so someone cannot call this while the random number is being rolled

        rolling = true;

        //initate the random number request
        Chainlink(vrfCoordinator).requestRandomWords(
        s_keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
       );
    
    }

    function forceDrawWinner() public requireOpen onlyAdmin{

        require(rolling, "roll not in progress");

        // Start a new raffle

        raffleNonce ++;
        nonce = 0;
        endTime[raffleNonce] = block.timestamp + raffleDuration;
        rolling = false;
    }


//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Internal and external functions this contract has:      ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

    // Put internal functions here: (There should NOT be any msg.sender or tx.origin in any function marked with internal)


    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {

        require(msg.sender == vrfCoordinator, "Not Authorized");
        
        fulfillRandomWords(requestId, randomWords);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal {

        requestId; // Tell remix I am aware of this variable not being used

        // roll the winner

        uint256 randomValue = (randomWords[0] % (nonce + 1));

        winner[raffleNonce] = list[raffleNonce][randomValue];

        // send the winner the pot

        emit WinnerDrawn(winner[raffleNonce], USDT.balanceOf(address(this)), nonce);

        USDT.transfer(winner[raffleNonce], USDT.balanceOf(address(this)));

        // Start a new raffle

        raffleNonce ++;
        nonce = 0;
        endTime[raffleNonce] = block.timestamp + raffleDuration;
        rolling = false;
    }

}
    
//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Contracts that this contract uses, contractception!     ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

interface ERC20{
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
    function decimals() external view returns (uint8);
}


interface Chainlink{
    function requestRandomWords(bytes32 keyHash, uint64 subId, uint16 minimumRequestConfirmations, uint32 callbackGasLimit, uint32 numWords) external returns (uint256 requestId);
}
