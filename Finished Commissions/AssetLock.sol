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

contract AssetLock{

//// This contract is a locking contract that locks all tokens and ETH sent to it until a certain time set by the deployer (admin) of the contract

    //How to setup

    // Step 1: Deploy the contract
    // Step 2: Call BeginLock() with time in seconds in "HowLong" to begin the lock
    // Step 3: Send tokens and ETH to this contract to lock them
    // Step 4: Once the time is over, you can unlock them using the sweep functions

//// Commissioned by Walledgarden#0002 on 7/25/2022

    // the constructor that activates when you deploy the contract, this is where you change settings before deploying.

    constructor(){

        admin = msg.sender;
    }


//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////


//// Special Variables go here:

    ERC20 Token;

//// All the Variables that this contract uses

    address admin;
    uint ReleaseTime;
    bool Locked;

    modifier onlyAdmin{

        require(msg.sender == admin, "You can't call this function because you are not the admin...");
        _;
    }

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    // Put visible functions (Buttons that people press) here:

    function BeginLock(uint Howlong) public onlyAdmin {

        require(Locked == false, "You have already started a lock");

        ReleaseTime = block.timestamp + Howlong;
        Locked = true;
    }

// Sweep lets you withdraw ETH, sweeptoken lets you withdraw tokens.

    function sweep() public onlyAdmin{

        require(block.timestamp > ReleaseTime, "This function is disabled until the locking period is finished");

        (bool sent,) = admin.call{value: (address(this)).balance}("");
        require(sent, "transfer failed");

        Locked = false;
    }

    function sweepToken(ERC20 WhatToken) public onlyAdmin{

        require(block.timestamp > ReleaseTime, "This function is disabled until the locking period is finished");

        WhatToken.transfer(admin, WhatToken.balanceOf(address(this)));

        Locked = false;
    }

    function sweepNFT(NFT WhatNFT, uint TokenID) public onlyAdmin{

        require(block.timestamp > ReleaseTime, "This function is disabled until the locking period is finished");

        WhatNFT.transferFrom(address(this), admin, TokenID);

        Locked = false;
    }

    function timeLeft() public view returns (uint){

        if(block.timestamp > ReleaseTime){

            return 0;
        }
        else{return ReleaseTime - block.timestamp;}
    }



//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Internal and external functions this contract has:      ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    // Put internal functions here: (There should NOT be any msg.sender or tx.origin in here)


//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////                 Functions used for UI data                   ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    
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
interface NFT{
    function transferFrom(address, address, uint256) external;
    function balanceOf(address) external returns (uint);
}
