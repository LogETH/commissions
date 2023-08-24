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

    // Step 1: Deploy the contract
    // Step 2: Microwave some instant ramen
    // Step 3: Put on your programming accessories 
    // Step 4: Make blockchain go beep boop and code

//// Commissioned by @kommissar29 on 8/18/2023

    // the constructor that activates when you deploy the contract, this is where you change settings before deploying.

    constructor(){

        USDT = ERC20(0x0000000000000000000000000000000000000000); // What token this contract uses
        admin = msg.sender;

        raffleDuration = 1 weeks; // How long the raffle should take
        limited = false; // Does this raffle allow contributing more than once per raffle?

        cost = 1*1e18; // How much a single contrubition should cost, 1*1e18 = 1 USDT, change the first number to edit the amount.

        // Wallets where the fees go to:

        taxWallet[1] = 0x0000000000000000000000000000000000000000; // 23.3%
        taxWallet[2] = 0x0000000000000000000000000000000000000000; // 23.3%
        taxWallet[3] = 0x0000000000000000000000000000000000000000; // 23.3%
        taxWallet[4] = 0x0000000000000000000000000000000000000000; // 20.1%

        refAddress = Referral(0x0000000000000000000000000000000000000000);
    }


//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////


//// Special Variables go here:

    ERC20 USDT;
    Referral refAddress;

//// All the Variables that this contract uses

    uint public raffleNonce; // What number raffle we are on, starts at 0, you can use previous numbers to look up data about previous raffles

    mapping(uint => mapping (address => bool)) public hasContributed; // Who has contributed to the raffle
    mapping(uint => mapping (uint => address)) public list;           // Who is in the raffle
    mapping(uint => address) public winner;                           // The winners of the raffles
    mapping(uint => uint) public endTime;                             // The time the raffle's winner is drawn
    mapping(uint => uint) internalPot;                                // The current pot with fees added



    uint public raffleDuration;                                 // How long the raffle lasts for
    address public admin;                                       // The address that is allowed to use admin functions
    uint public nonce;                                          // How many contributions the current raffle has received, starts at 0 so add 1 to get the true amount.
    uint public cost;                                           // How much it costs to contribute to the pot
    bool open;
    bool limited;                                               // Whether the raffle allows for multiple entries or not.
    address[] taxWallet;

    
//// Modifiers

    modifier onlyAdmin{require(msg.sender == admin,"Not Authorized");_;}
    modifier requireOpen{require(open,"Not Initalized");_;}


//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


//// Put visible functions (Buttons that people press) here:

    // Begins the raffle

    function initializeRaffle() public onlyAdmin{

        open = true;
        
    }

    // Lets someone contribute

    function contribute(uint HowManyTimes) public requireOpen{

        require(HowManyTimes != 0, "Cannot be zero");

        // If set, restrict contributing once per address for each raffle.
        if(limited){require(!hasContributed[raffleNonce][msg.sender] && HowManyTimes == 1, "You can only contribute once each raffle");}

        USDT.transferFrom(msg.sender, address(this), cost*HowManyTimes); // Send the funds to the contract

        // enter the msg.sender into the raffle as many times as they paid for.

        for(uint i; i>HowManyTimes; i++){

            list[raffleNonce][nonce] = msg.sender;                       // List the msg.sender as a contributor
        }

        if(limited){hasContributed[raffleNonce][msg.sender] = true;}     // If set, keep track if the msg.sender has bought a ticket.

        internalPot[raffleNonce] += cost*HowManyTimes;

        nonce++;
    }

    function drawWinner() public requireOpen{

        require(block.timestamp > endTime[raffleNonce], "The raffle has not ended yet");

        winner[raffleNonce] = rollWinner(); // roll the winner

        // Handle the fees

        uint fees = (internalPot[raffleNonce]/100)*30; // 30% of the pot is taken as fees

        USDT.transfer(taxWallet[1], (fees/1000)*233);
        USDT.transfer(taxWallet[2], (fees/1000)*233);
        USDT.transfer(taxWallet[3], (fees/1000)*233);
        USDT.transfer(taxWallet[4], (fees/1000)*201);

        USDT.transfer(address(refAddress), fees/10);

        // send the winner the rest of the pot

        USDT.transfer(winner[raffleNonce], USDT.balanceOf(address(this)));

        // Start a new raffle

        raffleNonce ++;
        nonce = 0;
        endTime[raffleNonce] = block.timestamp + raffleDuration;
    
    }


//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Internal and external functions this contract has:      ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

    // Put internal functions here: (There should NOT be any msg.sender or tx.origin in here)

    function rollWinner() internal returns(address){


    }


//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////                 Functions used for UI data                   ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

    function pot(uint raffleID) public view returns(uint){

        return (internalPot[raffleID]/100)*70; // The pot is equal to the funds collected with 30% taken as fees
    }


    
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// Additional functions that are not part of the core functionality, if you add anything, please add it here ////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
    function something() public {

        blah blah blah blah;
    }
*/



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

interface Referral{


}
