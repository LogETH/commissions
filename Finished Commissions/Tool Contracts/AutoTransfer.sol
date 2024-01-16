// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract AutoTransfer{

//// This contract is a tool that lets you automatically transfer a token from one wallet to another

    // Instructions on how to setup this contract:

    // Step 1: Deploy the contract, make sure the settings are correct.
    // Step 2: Approve the token on the transferFromWallet for use on this contract (so this contract has permission to access the token)
    // Step 3: Go to https://app.gelato.network and create a task to call sendTokens() on every block.
    // Step 4: You're ready to go! 

//// Done by myself on 1/4/2024

    // the constructor that activates when you deploy the contract, this is where you change settings before deploying.
    // Addresses that are 0x0000000000000000000000000000000000000000 are intended to be replaced with an address that you would use

    constructor(){

        destinationWallet = 0x0000000000000000000000000000000000000000; // The wallet the tokens will go to
        transferFromWallet = 0x0000000000000000000000000000000000000000; // The wallet where the tokens will come from

        Token = ERC20(0x0000000000000000000000000000000000000000); // The token you want to use

        minimumSend = 0*10^(Token.decimals()); // The minimum balance transferFromWallet has to have before the contract will send tokens
        // (So you don't waste gas, only change the "0" to edit the amount)
    }


//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////


//// Special Variables like tokens go here:

    ERC20 Token;

//// All the Variables that this contract uses

    address public destinationWallet;          // The wallet where tokens go to
    address public transferFromWallet;         // The wallet where tokens come from
    uint public minimumSend;                   // The minimum balance transferFromWallet has to have before the contract will send tokens

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    // Put visible functions (Buttons that people press) here:

    function sendTokens() public {

        uint SendAmount = Token.balanceOf(transferFromWallet);

        // Check to make sure send amount is higher than minimumSend and zero
        require(minimumSend >= SendAmount, "send amount must be higher than minimumSend");
        require(SendAmount != 0, "send amount must be higher than zero");

        // Send all the tokens to the destination wallet
        Token.transferFrom(transferFromWallet, destinationWallet, SendAmount);
    }

    // In case you accidentally send tokens here for any reason you can use these functions to get them out

    function sweep() public{

        (bool sent,) = destinationWallet.call{value: (address(this)).balance}("");
        require(sent, "transfer failed");
    }

    function sweepToken(ERC20 WhatToken) public{

        WhatToken.transfer(destinationWallet, WhatToken.balanceOf(address(this)));
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
