// SPDX-License-Identifier: CC-BY-SA 4.0
//https://creativecommons.org/licenses/by-sa/4.0/

// TL;DR: The creator of this contract (@LogETH) is not liable for any damages associated with using the following code
// This contract must be deployed with credits toward the original creator, @LogETH.
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests I endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the license.

// By deploying this contract, you agree to the licence above and the terms and conditions that come with it.

pragma solidity >=0.7.0 <0.9.0;

// What is this contract? 
// This contract is a module that can be attached to ANY ERC721 NFT (yes, by any I really mean any) to create a working staking mechanism. 
// Can be useful for constant Uniswap V3 liquidity staking or simply distributing a token between NFT owners.
// if you ever reuse this contract, make sure to credit Log! (Log#7730 on discord, LogETH on github)
//
//                                             HOW TO USE THE CONTRACT:
//                                             Coded with love by Log
//
// STEP 1: Change the activator address to your address, this is the only address that can call the activate function.
// STEP 2: Deploy this contract and call the activate function with the NFT, token address, and stake factor the contract will use. 
// The stake factor is how many coins 1 NFT gets per BLOCK. Don't forget about decimals!
// STEP 3: Fill this contract with tokens to give out as rewards, just send them like how you would send any other token.

// OTHER:
// This contract supports proxies and multisig wallets like gnosis safe.
// This contract DOES NOT support "fee on transfer" ERC20 tokens.
// This contract is setup so its easily usable from any explorer, but 
// if you would like to add more info points to use in an interface, you can easily grab a variable by adding in a "get" function

// Contract Commissioned by bday on 3/3/2022

contract NFTStakingUpgradable{

    //YO. CHANGE THIS TO YOUR ADDRESS
    address activator = 0xC65423A320916d7DAF86341De6278d02c7E1D3B1;

////The Contracts this contract uses goes here, OnePercent and NOKO token

    NFT OnePercent;
    ERC20 NOKO;

////Variables that this contract uses, the first one counts time, the second one keeps track of how many NFTs you staked
////Third one keeps track of which NFT you staked, and the fourth makes sure you can't use any buttons until you finished the steps to set this contract up.

    mapping(address => uint) TimeStaked;
    mapping(address => uint) StakingMultiplier;
    mapping(uint => address) TokenIDstaked;
    uint totalstaked;
    bool isActivated;
    uint StakeFactor;

//// Additional variables that are not part of the core contract go here:



////The Activate function tells the contract what the heck the NFT and token addresses are, plus the stake factor, which tells the contract how many tokens to give per block.
////it has to be called or else the entire contract wont work

////You can call it multiple times to update the token or NFT it uses.
////Don't forget about decimals when entering the StakeFactor!!! <- LOOK

    function Activate(NFT OnePercentAddress, ERC20 TokenThatYouWant, uint _StakeFactor) public {

        require(msg.sender == activator);

        OnePercent = OnePercentAddress;
        NOKO = TokenThatYouWant;
        StakeFactor = _StakeFactor;
        isActivated = true;
    }

////This button claims your rewards, that's it.

    function Claim() public{

        require(isActivated = true, "Contract has not been activated yet, call the Activate function");

        uint Time;
        uint Unclaimed;

        Time = this.CalculateTimeStaked(msg.sender);
        Unclaimed = this.CalculateRewards(msg.sender, Time);

        require(NOKO.balanceOf(address(this)) >= Unclaimed, "This contract is out of tokens to give as rewards! Ask devs to do something");
        TimeStaked[msg.sender] = block.timestamp;
        NOKO.transfer(msg.sender, Unclaimed);
    }

////The Stake button stakes one NFT. It also claims any existing rewards. You can call it multiple times to stake multiple times.

    function Stake(uint256 TokenID) public {

        require(isActivated = true, "Contract has not been activated yet, call the Activate function");
        require(StakingMultiplier[msg.sender] <= 100, "You cannot stake more than 100 NFTs");

        uint LocalTime;
        uint Unclaimed;

        LocalTime = this.CalculateTimeStaked(msg.sender);
        Unclaimed = this.CalculateRewards(msg.sender, LocalTime);

        require(NOKO.balanceOf(address(this)) >= Unclaimed, "This contract is out of tokens to give as rewards! Ask devs to do something");
        NOKO.transfer(msg.sender, Unclaimed);

        ////////////////////////////////////////////////////////////////////

        OnePercent.transferFrom(msg.sender, address(this), TokenID);

        TokenIDstaked[TokenID] = msg.sender;
        TimeStaked[msg.sender] = block.timestamp;

        StakingMultiplier[msg.sender] += 1;
        totalstaked += 1;
    }

////This button withdraws one NFT, it also claims any existing rewards. You can call it multiple times to withdraw multiple times.

    function Withdraw(uint TokenID) public{
        
        require(isActivated = true, "Contract has not been activated yet, call the Activate function");

        uint LocalTime;
        uint Unclaimed;

        LocalTime = this.CalculateTimeStaked(msg.sender);
        Unclaimed = this.CalculateRewards(msg.sender, LocalTime);

        require(NOKO.balanceOf(address(this)) >= Unclaimed, "This contract is out of tokens to give as rewards! Ask devs to do something");
        NOKO.transfer(msg.sender, Unclaimed);

        //////////////////////////////////////////////////////////////////////

        require(msg.sender == TokenIDstaked[TokenID], "You can't withdraw an NFT that isn't yours!");

        OnePercent.transferFrom(address(this), msg.sender, TokenID);
        TimeStaked[msg.sender] = block.timestamp;

        StakingMultiplier[msg.sender] -= 1;
        totalstaked -= 1;
    }

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// The internal/external functions this contract uses, it compresses big commands into tiny ones so its easier to implement in the actual buttons. ////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////msg.sender and tx.origin should NOT be used in any of the below functions.
  
    function CalculateTimeStaked(address YourAddress) external view returns (uint256){

        uint LocalTime;
        uint ActualTime;
        LocalTime = TimeStaked[YourAddress];

        ActualTime = block.timestamp - LocalTime;

        if(ActualTime == block.timestamp){

            ActualTime = 0;
        }

        return ActualTime;

    }

////This function calculates rewards. Blocks on Fantom fluxuate between 0.9-1.1 seconds, so it may be slightly inaccurate if you assume 1 block = 1 second.
////If you're using this on another chain, get that chain's blocktime, and use math to figure out an appropriate StakeFactor.

    function CalculateRewards(address YourAddress, uint256 StakeTime) external view returns (uint256){

        uint LocalReward;
        LocalReward = StakeTime;

        LocalReward = LocalReward * StakingMultiplier[YourAddress] * StakeFactor;

        return LocalReward;

    }

///////////////////////////////////////////////////////////
//// The internal/external functions used for UI data  ////
///////////////////////////////////////////////////////////

    function GetUnclaimedRewards(address YourAddress) external view returns (uint256){

        uint LocalTime;
        uint Unclaimed;

        LocalTime = this.CalculateTimeStaked(YourAddress);
        Unclaimed = this.CalculateRewards(YourAddress, LocalTime);

        return Unclaimed;

    }

    function DetectOwnership(address YourAddress, uint256 TokenID) external view returns (bool){

        if(TokenIDstaked[TokenID] == YourAddress){

            return true;

        }
        else{

            return false;

        }

    }

    function GetStakingMultiplier(address YourAddress) external view returns (uint){

        return StakingMultiplier[YourAddress];

    }

    function GetTotalStaked() external view returns (uint){

        return totalstaked;

    }

    
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// Additional functions that are not part of the core functionality, if you add anything, please add it here ////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////




}
    
/////////////////////////////////////////////////////////////////////////////////////////
//// The functions that this contract calls to the other contracts, contractception! ////
/////////////////////////////////////////////////////////////////////////////////////////

interface NFT{
    function transferFrom(address, address, uint256) external;
}
interface ERC20{
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
}
