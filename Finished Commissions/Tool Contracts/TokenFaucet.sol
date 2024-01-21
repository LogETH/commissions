// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract Faucet{

//// This contract is a token faucet that allows users to receive an amount of tokens. 
//// Has basic measures to prevent abuse, but don't use this for tokens that are worth money

    // How to setup:

    // Step 1: Configure the settings in the constructor and deploy the contract
    // Step 2: Send tokens to this contract like how you would normally send someone a token
    // Step 3: The contract should be ready to use from there, make sure you refill once in a while.

//// Made for myself

    // the constructor that activates when you deploy the contract, this is where you change settings before deploying.
    // Addresses that are 0x0000000000000000000000000000000000000000 are intended to be replaced with an address that you would use

    constructor(){

        giveAmount = 1000*(10**token.decimals());   // The number of tokens to give out. the default value is 1000 tokens
        cooldown = 86400;                           // The cooldown in seconds. 86400 seconds is 1 day

        token = ERC20(0x0000000000000000000000000000000000000000);
    }

    ERC20 token;
    uint giveAmount;
    uint cooldown;
    mapping(address => uint) timeLock;

    // Gives you giveAmount tokens

    function Gettokens() public {

        require(block.timestamp >= timeLock[msg.sender] + cooldown, "Your cooldown is in progress");
        require(token.balanceOf(msg.sender) == 0, "You already have tokens.");
        require(msg.sender == tx.origin, "You cannot receive tokens with a contract");

        timeLock[msg.sender] = block.timestamp;
        token.transfer(msg.sender, giveAmount);
    }
}

interface ERC20{
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
    function decimals() external view returns(uint8);
}
