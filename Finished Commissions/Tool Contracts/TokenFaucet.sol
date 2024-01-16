// SPDX-License-Identifier: CC-BY-SA 4.0
//https://creativecommons.org/licenses/by-sa/4.0/

// a really quick token faucet I coded, feel free to use this however you want

pragma solidity >=0.8.0 <0.9.0;

    // How to setup:

    // Step 1: Configure the settings in the constructor and deploy the contract
    // Step 2: Send tokens to this contract like how you would normally send someone a token
    // Step 3: The contract should be ready to use from there, make sure you refill once in a while.

contract Faucet{

    constructor(){

        GiveAmount = 1000*(10**Token.decimals());   // The number of tokens to give out. the default value is 1000 tokens
        Cooldown = 86400;                           // The cooldown in seconds. 86400 seconds is 1 day
    }

    ERC20 Token = ERC20(0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735);
    uint GiveAmount;
    uint Cooldown;
    mapping(address => uint) Clock;

    // Gives you GiveAmount tokens

    function GetTokens() public {

        require(block.timestamp >= Clock[msg.sender] + Cooldown, "Your cooldown is in progress");
        require(Token.balanceOf(msg.sender) == 0, "You already have tokens.");
        require(msg.sender == tx.origin, "You cannot receive tokens with a contract");

        Clock[msg.sender] = block.timestamp;
        Token.transfer(msg.sender, GiveAmount);
    }
}

interface ERC20{
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
    function decimals() external view returns(uint8);
}
