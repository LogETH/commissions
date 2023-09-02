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

contract RepeatingLottery{

//// This contract is a lottery that repeats itself

    // Instructions on how to setup the contract:
    // https://docs.google.com/document/d/1dA6kW0114xwe_flailso4VwDyUrCXknFjhqKydbBT5U/edit


//// Commissioned by someone on 8/18/2023

    // the constructor that activates when you deploy the contract, this is where you change settings before deploying.

    constructor(){

        USDT = ERC20(0x2e1F920a4C157BD89606792081f73C6439548817);   // What token this contract uses
        admin = msg.sender;                                         // Makes you the admin

        raffleDuration = 60 seconds;                                // How long the raffle should take

        limited = false;                                            // Does this raffle restrict contributing to once per raffle?

        cost = 10*1e18; // How much a single contrubition costs, 10*1e18 = 10 USDT. Change the first number to edit the amount.

        //// Wallets where the fees go to:

        taxWallet[0] = 0x0000000000000000000000000000000000000000;  // 23.3%
        taxWallet[1] = 0x0000000000000000000000000000000000000000;  // 23.3%
        taxWallet[2] = 0x0000000000000000000000000000000000000000;  // 23.3%
        taxWallet[3] = 0x0000000000000000000000000000000000000000;  // 20.1%

        //// Contract that handles referrals

        refAddress = Ref(0x095E3ca5b7a13c3cD75Bbdb5B4adD0a2Cbd738Fb); // referral contract address
        refMultiplier = 1;                                          // How many referral entries should one contribution give?

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


//// Contract variables

    ERC20 public USDT;
    Ref public refAddress;

//// Mappings

    uint public raffleNonce; // What number raffle we are on, starts at 0, you can use previous numbers to look up data about previous raffles

    mapping(uint => mapping (address => bool)) public hasContributed; // Who has contributed to the raffle
    mapping(uint => mapping (uint => address)) public list;           // List of addresses in the raffle
    mapping(uint => address) public winner;                           // The winners of the raffles
    mapping(uint => uint) public endTime;                             // The time the raffle's winner is drawn
    mapping(uint => uint) internalPot;                                // The current pot with fees added
    mapping(uint => address) taxWallet;                               // A list of wallets where the fees go to

//// Single variables

    address public admin;                                       // The address that is allowed to use admin functions

    bool public open;                                           // Is the raffle initalized?
    bool public limited;                                        // Whether the raffle allows for multiple entries or not.
    bool rolling;                                               // If the winner is currently being drawn, prevents the contract from accedentally drawing twice.

    uint public raffleDuration;                                 // How long the raffle lasts for
    uint public nonce;                                          // How many contributions the current raffle has received
    uint public cost;                                           // How much it costs to contribute to the pot
    uint public refMultiplier;                                  // How many entries into the referral pot should one referral give?
    uint remTime;                                               // The remaining amount of time if the raffle is paused.
    
//// Modifiers

    modifier requireNotRolling  {require(!rolling,           "Cannot use while rolling");_;}
    modifier onlyAdmin          {require(msg.sender == admin,"Not Authorized");_;}
    modifier requireClosed      {require(!open,              "Not Closed");_;}
    modifier requireOpen        {require(open,               "Not Open");_;}

//// Chainlink variables 

    uint64 s_subscriptionId;
    address vrfCoordinator;
    bytes32 s_keyHash;
    uint32 public callbackGasLimit = 200000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

//// Events

    event Contribution(address indexed _contributor, uint _numTimes, address indexed _referralAddress);
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

    function pauseRaffle() public onlyAdmin requireOpen requireNotRolling{

        open = false;
        remTime = endTime[raffleNonce] - block.timestamp;
    }

    function resumeRaffle() public onlyAdmin requireClosed{

        open = true;
        endTime[raffleNonce] = remTime + block.timestamp;
    }

    function changeCallbackGasLimit(uint32 howmuch) public onlyAdmin{

        callbackGasLimit = howmuch;
    }

    // Lets someone contribute, put 0x0000...0000 for no referral address.

    function contribute(uint HowManyTimes, address referralAddress) public requireOpen{

        require(HowManyTimes != 0, "Cannot be zero");
        require(referralAddress != msg.sender, "You cannot refer yourself");
        require(!rolling, "Cannot contribute when the winner is being rolled");

        // If set, restrict contributing once per address for each raffle.
        if(limited){require(!hasContributed[raffleNonce][msg.sender] && HowManyTimes == 1, "You can only contribute once each raffle");}

        USDT.transferFrom(msg.sender, address(this), cost*HowManyTimes); // Send the funds to the contract

        //// Handle the fees

        uint fees = (cost*HowManyTimes/100)*30; // 30% of the pot is taken as fees

        USDT.transfer(taxWallet[0], (fees/1000)*233);
        USDT.transfer(taxWallet[1], (fees/1000)*233);
        USDT.transfer(taxWallet[2], (fees/1000)*233);
        USDT.transfer(taxWallet[3], (fees/1000)*201);

        USDT.transfer(address(refAddress), fees/10);

        // enter the msg.sender into the raffle as many times as they paid for.

        for(uint i; i < HowManyTimes; i++){

            list[raffleNonce][nonce] = msg.sender;                       // List the msg.sender as a contributor
            nonce++;                                                     // move up the list by one
        }

        if(limited){hasContributed[raffleNonce][msg.sender] = true;}     // If set, keep track if the msg.sender has bought a ticket.

        internalPot[raffleNonce] += cost*HowManyTimes;

        if(referralAddress != address(0)){

            refAddress.enterReferral(referralAddress, HowManyTimes*refMultiplier);
        }

        emit Contribution(msg.sender, HowManyTimes, referralAddress);
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

        // send the winner the pot

        //initate the random number request
        Chainlink(vrfCoordinator).requestRandomWords(
        s_keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
       );

       // if this request fails for a reason such as the winner being banned from receiving USDT, 
       // forceDrawWinner() can be used to force restart the raffle
    
    }

    function forceDrawWinner() public requireOpen onlyAdmin{

        require(rolling, "roll not in progress");

        USDT.transfer(taxWallet[3], USDT.balanceOf(address(this)));

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

        uint256 randomValue = (randomWords[0] % (nonce));
        winner[raffleNonce] = list[raffleNonce][randomValue];

        // send the winner the rest of the pot

        emit WinnerDrawn(winner[raffleNonce], USDT.balanceOf(address(this)), nonce);

        USDT.transfer(winner[raffleNonce], USDT.balanceOf(address(this)));

        // Start a new raffle

        raffleNonce ++;
        nonce = 0;
        endTime[raffleNonce] = block.timestamp + raffleDuration;
        rolling = false;
    }


//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////                 Functions used for UI data                   ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    function pot(uint raffleID) public view returns(uint){

        return (internalPot[raffleID]/100)*70; // The pot is equal to the funds collected with 30% taken as fees
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

interface Ref{

    function enterReferral(address, uint) external;
}

interface Chainlink{
    function requestRandomWords(bytes32 keyHash, uint64 subId, uint16 minimumRequestConfirmations, uint32 callbackGasLimit, uint32 numWords) external returns (uint256 requestId);
}
