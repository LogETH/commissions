// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract TokenSplitter{

//// This contract splits tokens between two users without the need of trusting either of them.

    // How to use the contract:

    // Step 1: Deploy the contract, make sure everything in the constructor is correct, you cannot change them later.
    // Step 2: Have tokens sent to this contract like how you would normally send a token.
    // Step 3: Call splitTokens() to have the contract send them to both addresses.

    // Just in case someone sends the wrong token into this contract, you can use changeToken() to change the token this contract uses.

//// Made by myself (@LogETH)

    // the constructor that activates when you deploy the contract, this is where you change settings before deploying.
    // address that are 0x0000...0000 are intended to be replaced with ones that you would use

    constructor(){

        Token = ERC20(0x0000000000000000000000000000000000000000);          // The token this contract uses
        addressOne = 0x0000000000000000000000000000000000000000;            // The first person's address
        addressTwo = 0x0000000000000000000000000000000000000000;            // The second person's address

        split = 20;                                                         // How much % the second person receives (Ex: 20 means an 80/20 split)
        require(split < 100, "split cannot be 100 or higher");
    }


//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////


//// All the Variables that this contract uses

    ERC20 Token;            // The token this contract uses
    address addressOne;     // The first person's address
    address addressTwo;     // The second person's address
    uint split;             // The % amount the second person receives


//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    // The function that splits the tokens, anyone is able to call it

    function splitTokens() public {

        Token.transfer(addressTwo,(Token.balanceOf(address(this))/100)*split);   // Sends split % to the second address
        Token.transfer(addressOne, Token.balanceOf(address(this)));              // Sends the remaining amount to the first address
    }

    // Just in case someone sends the wrong token into this contract, you can use this function to change the token this contract uses

    function changeToken(ERC20 _token) public {

        require(msg.sender == addressOne || msg.sender == addressTwo); // Only the users of this contract can change the token
        Token = _token; // Changes the token
    }

}

// Interface so this contract is able to handle tokens

interface ERC20{
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
}
