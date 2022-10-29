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

//// What is this contract? 

//// This contract is a dynamic staking system
//// Most of my contracts have an admin, this contract's admin is the deployer variable

    // How to Setup:

    // Step 1: Change the values in the constructor to the ones you want
    // Step 2: Deploy the contract
    // Step 3: To start the contract, simply call startContract() with the amount of time and amount of tokens it should give out.
    // Step 5: It should be ready to use from there

//// Commisioned by someone on 10/25/2022

contract DynamicStaking {

//// The constructor, this is where you change settings before deploying
//// make sure to change these parameters to what you want

    constructor () {

        rewardToken = ERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
        LPtoken = ERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

        deployer = msg.sender;
    }

//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////

//// Variables that make the internal parts of this contract work, I explained them the best I could

    ERC20 public LPtoken;                    // The address of the LP token that is the pool where the LP is stored
    ERC20 public rewardToken;                       // The address of wrapped ethereum
    address deployer;                          // The address of the person that deployed this contract

//// Variables that are part of the airdrop portion of this contract:

    uint public lastTime;                       // The last time the yield was updated
    uint public yieldPerBlock;                  // How many tokens to give out per block
    uint public endTime;                        // The block.timestamp when the airdrop will end
    bool public started;                        // Tells you if the airdrop has started
    bool public ended;                          // Tells you if the airdrop has ended
    address[] list;                      // A list of addresses that interacted with this contract
    mapping(address => bool) listed;
    mapping(address => uint) pendingReward;     // Your pending reward, does not include rewards after lastTime. Use getReward() for a more accurate amount.

    mapping(address => uint) stakedBalance;
    uint public totalStaked;


    modifier onlyDeployer{

        require(deployer == msg.sender, "Not deployer");
        _;
    }

    
//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

    function StartContract(uint HowManyDays, uint HowManyTokens) onlyDeployer public {

        require(!started, "You have already started the staking system");

        endTime = HowManyDays * 86400 + block.timestamp;

        uint togive = HowManyTokens;

        rewardToken.transferFrom(msg.sender, address(this), HowManyTokens);

        yieldPerBlock = togive/(endTime - block.timestamp);

        lastTime = block.timestamp;
        started = true;
    }

    function sweep() public{

        require(msg.sender == deployer, "Not deployer");

        (bool sent,) = msg.sender.call{value: (address(this)).balance}("");
        require(sent, "transfer failed");
    }

    function claimReward() public {

        require(started, "The airdrop has not started yet");

        updateYield();

        rewardToken.transfer(msg.sender, pendingReward[msg.sender]);
        pendingReward[msg.sender] = 0;
    }

    function deposit(uint HowManyTokens) public {

        updateYield();

        rewardToken.transferFrom(msg.sender, address(this), HowManyTokens);

        if(!listed[msg.sender]){

            listed[msg.sender] = true;
            list.push(msg.sender);
        }
        stakedBalance[msg.sender] += HowManyTokens;
        totalStaked += HowManyTokens;
    }

    function withdraw(uint HowManyTokens) public {

        updateYield();

        require(HowManyTokens <= stakedBalance[msg.sender] || HowManyTokens == type(uint256).max, "You cannot withdraw more than your staked balance");

        if(HowManyTokens == 0 || HowManyTokens == type(uint256).max){

            HowManyTokens = stakedBalance[msg.sender];
        }

        LPtoken.transfer(msg.sender, HowManyTokens);

        stakedBalance[msg.sender] -= HowManyTokens;
        totalStaked -= HowManyTokens;

        
    }

    
//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Internal and external functions this contract has:      ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////




//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////                 Functions used for UI data                   ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////



    // "Local" variables that are deleted at the end of the transaction.

    uint LTotal;
    uint period;

    function updateYield() public {

        if(!started || ended){return;}

        if(block.timestamp >= endTime){
            
            lastTime = endTime;
            ended = true;
        }

        LTotal = totalStaked;
        period = block.timestamp - lastTime;

        for(uint i; i < list.length; i++){

            pendingReward[list[i]] += ProcessReward(list[i]);
        }

        delete LTotal;
        delete period;
        lastTime = block.timestamp;
    }

    function ProcessReward(address who) internal view returns (uint reward) {

        uint percent = stakedBalance[who]*1e23/LTotal;

        reward = yieldPerBlock*period*percent/100000;
    }

    function ProcessRewardALT(address who) internal view returns (uint reward) {

        uint percent = stakedBalance[who]*1e23/totalStaked;

        reward = yieldPerBlock*(block.timestamp - lastTime)*percent/100000;
    }

    function GetReward(address who) public view returns(uint reward){

        if(lastTime == 0){return 0;}

        reward = ProcessRewardALT(who) + pendingReward[who];
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
    function transferFrom(address, address, uint256) external returns(bool);
    function transfer(address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint);
    function decimals() external view returns(uint8);
    function approve(address, uint) external returns(bool);
    function totalSupply() external view returns (uint256);
}
