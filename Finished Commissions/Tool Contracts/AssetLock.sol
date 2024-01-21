// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract assetLock{

//// This contract is a locking contract that locks all tokens and NFTs sent to it until a certain time set by the deployer (admin) of the contract
//// This contract will NOT accept any network's native gas token, please use wETH or your respective network's wrapped gas token instead.

    //How to setup

    // Step 1: Deploy the contract
    // Step 2: Call BeginLock() with time in seconds in "HowLong" to begin the lock
    // Step 3: Send tokens and NFTs to this contract to lock them
    // Step 4: Once the time is over, you can unlock them using the sweep functions

//// Commissioned by Walledgarden#0002 on 7/25/2022

    // the constructor that activates when you deploy the contract

    constructor(){

        admin = msg.sender; // makes you (the deployer of the contract) the admin of this contract
    }


//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////


//// Special Variables go here:

    ERC20 Token;

//// All the Variables that this contract uses

    address admin;          // The admin of this contract (Also the address this contract will withdraw to)
    uint ReleaseTime;       // The time when this contract will be unlocked, calculated when you begin the lock

//// Modifiers

    modifier onlyAdmin{

        require(msg.sender == admin, "You can't call this function because you are not the admin");
        _;
    }

    modifier locked{

        require(block.timestamp > ReleaseTime, "This function is disabled until the locking period is finished");
        _;
    }

    receive() external payable{

        revert("You cannot deposit a network's native gas token, use wETH or your respective network's wrapped gas token instead");
    }

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    // Put visible functions (Buttons that people press) here:

    function BeginLock(uint How_Many_Days) public onlyAdmin locked{

        require(How_Many_Days <= 365, "The longest you can lock this contract for is 1 year");

        ReleaseTime = block.timestamp + (How_Many_Days * 1 days);
    }

    // withdrawToken() lets you withdraw tokens, withdrawNFT() lets you withdraw NFTs

    function withdrawToken(ERC20 tokenAddress) public onlyAdmin locked{

        tokenAddress.transfer(admin, tokenAddress.balanceOf(address(this)));
    }

    function withdrawNFT(NFT NFTAddress, uint TokenID) public onlyAdmin locked{

        NFTAddress.transferFrom(address(this), admin, TokenID);
    }

    // function for looking up how much time in *seconds* you have left

    function timeLeft() public view returns (uint){

        if(block.timestamp > ReleaseTime){
            return 0;
        }
        else{return ReleaseTime - block.timestamp;}
    }

}
    
//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Contracts that this contract uses, contractception!     ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

interface ERC20{
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
}
interface NFT{
    function transferFrom(address, address, uint256) external;
    function balanceOf(address) external returns (uint);
}
