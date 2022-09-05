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

contract StableMarket{

//// This contract is a simple DEX and ERC20 engineered to support a specific stablecoin

    // Put instructions on how to setup the completed contract here:

    // Step 1: Deploy the contract with the buy/sell token and treasury wallet configured
    // Step 2: manually approve the buy/sell token for this contract on the treasury wallet.

    // To change the token, follow these steps:

    // Step 1: Swap the entire treasury wallet for the new token people would use to buy and sell
    // Step 2: Approve the new Token for this contract on the treasury wallet
    // Step 3: Call ChangeToken() with the new token.

//// Commissioned by spagetti#7777 on 8/15/2022

    // the constructor that activates when you deploy the contract, this is where you change settings before deploying.

    constructor(){

        Token = ERC20(0xd94015B7325dEE9dE0Cf89707e4Ae7D5692872f4);
        treasuryWallet = 0x04Ca8Ff5627412B78CdaF474fDF861aF42B3BdcF;

        name = "Stable";
        symbol = "STB";

        decimals = 18; // DAI has 18 decimals, so this token should match
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

    address public treasuryWallet;
    uint public TotalMinted;
    bool public sellPause;
    address admin;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // name is text, decimals is a number, the symbol is text, and the total supply is a number, blah blah blah
    // Public so you can see what it is anytime

    string public name;
    uint8 public decimals;
    string public symbol;
    uint public totalSupply;

    modifier OnlyAdmin{

        require(msg.sender == admin, "You cannot call this function as you are not the admin");
        _;
    }

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    // Put visible functions (Buttons that people press) here:

        // The button you press to send tokens to someone

    function transfer(address _to, uint256 _value) public returns (bool success) {

        require(balanceOf[msg.sender] >= _value, "You can't send more tokens than you have");

        balanceOf[msg.sender] -= _value; // Decreases your balance
        balanceOf[_to] += _value; // Increases their balance, successfully sending the tokens
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // The function a DEX uses to trade your coins

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(balanceOf[_from] >= _value && allowance[_from][msg.sender] >= _value, "You can't send more tokens than you have or the approval isn't enough");

        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    // The function you use to approve your tokens for trading

    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true;
    }

    function SellForToken(uint HowMuch) public {
        
        require(sellPause == false, "you cannot sell when selling is disabled");

        burn(msg.sender, HowMuch);
        Token.transferFrom(treasuryWallet, msg.sender, HowMuch);
    }

    function BuyFromToken(uint HowMuch) public {

        Token.transferFrom(msg.sender, treasuryWallet, HowMuch);
        mint(msg.sender, HowMuch);
    }

    function pauseSelling(bool trueOrFalse) public OnlyAdmin{

        sellPause = trueOrFalse;
    }

    function ChangeToken(ERC20 WhatToken) public OnlyAdmin{

        Token = WhatToken;
    }


//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Internal and external functions this contract has:      ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    // Put internal functions here: (There should NOT be any msg.sender or tx.origin in here)

    function mint(address Who, uint HowMuch) internal {

        balanceOf[Who] += HowMuch;
        emit Transfer(address(0), Who, HowMuch);
        totalSupply += HowMuch;
    }

    function burn(address Who, uint HowMuch) internal {

        require(balanceOf[Who] >= HowMuch, "You cannot burn more tokens than you have");
        balanceOf[Who] -= HowMuch;
        emit Transfer(Who, address(0), HowMuch);
        totalSupply -= HowMuch;
    }


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

interface ERC20{
    function transferFrom(address, address, uint256) external returns(bool);
    function transfer(address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint);
    function decimals() external view returns(uint8);
    function approve(address, uint) external returns(bool);
    function totalSupply() external view returns (uint256);
}
