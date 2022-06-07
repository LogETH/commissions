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

contract SimpleDAO{

//// This contract is an ERC20 token that has a DAO module attached to it
//// People can vote on Proposals and stuff 
//// You cannot send or use tokens that are currently being used to vote btw.

    // How to setup:

    // Step 1: Deploy the contract
    // Step 2: That's pretty much it, all the tokens are sent to you, so go wild.

//// Commissioned by WojtekBB#8959 on 6/7/2022

    // the constructor that activates when you deploy the contract, this is where you change settings before deploying.

    constructor(){

        balanceOf[msg.sender] = 2000000*10**18;
        totalSupply = 2000000*10**18;
        name = "LOG token";
        decimals = 18;
        symbol = "LOG";

        MinProp = 10;                   // Minimum % of the total supply you need to create a proposal
        MaxVotingTime = 3600*24*7;      // How long a voting time lasts on a proposal

        admin = msg.sender;             // The admin is able to change everything above... but this is a DAO, do you really want that?
    }


//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////

//// All the Variables that this contract uses

    mapping (address => uint256) public balanceOf; 
    mapping (address => uint256) public FrozenTokens;
    mapping (address => mapping (address => uint256)) public allowance;

    uint Nonce;
    uint MinProp;



    string public name;
    string public symbol;
    address public admin;
    uint8 public decimals;
    uint public totalSupply;
    uint public MaxVotingTime;


    mapping (uint => uint) VoteTime;
    mapping (address => bool) Voted;
    mapping (uint => address) Proposal;
    mapping (address => uint) VoteTokens;
    mapping (address => bool) ProposalApproved;
    mapping (uint => mapping(bool => uint)) VoteBox;
    mapping (uint => mapping(uint => address)) userNonce;

    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    modifier adminOnly(){

        require(msg.sender == admin);
        _;
    }


//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    function EditMinProp(uint HowMuch) public adminOnly{

        MinProp = HowMuch;
    }

    function EditMaxVotingTime(uint HowMuch) public adminOnly{

        MinProp = HowMuch;
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {

        require(balanceOf[msg.sender] - FrozenTokens[msg.sender] >= _value, "You can't send more tokens than you have avalable");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(balanceOf[_from] - FrozenTokens[msg.sender] >= _value && allowance[_from][msg.sender] >= _value, "You can't send more tokens than you have avalable or the approval isn't enough");

        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); 
        return true;
    }

    function ProposeVote(address ProposalAddress) public {

        Nonce ++;
        require(balanceOf[msg.sender] >= MinProp*totalSupply/100, "You don't have enough tokens to make a proposal");
        VoteTime[Nonce] = block.timestamp;

        Proposal[Nonce] = ProposalAddress;
    }

    function Vote(uint ProposalID, bool TrueOrFalse, uint HowManyTokens) public {

        require(Voted[msg.sender] = false, "You already voted on this proposal!");
        require(block.timestamp - VoteTime[ProposalID] < MaxVotingTime, "Voting time is over!");

        Voted[msg.sender] = true;
        VoteTokens[msg.sender] += HowManyTokens;
        VoteBox[ProposalID][TrueOrFalse] += HowManyTokens;

        FrozenTokens[msg.sender] += HowManyTokens;
    }

    function FinalizePropResult(uint ProposalID) public {

        require(block.timestamp - VoteTime[ProposalID] > MaxVotingTime, "Voting has not ended yet!");
        if(VoteBox[ProposalID][true] > VoteBox[ProposalID][false]){ProposalApproved[Proposal[ProposalID]] = true;}

        uint x; 

        while(userNonce[ProposalID][x] != address(0)){

            FrozenTokens[userNonce[ProposalID][x]] -= VoteTokens[userNonce[ProposalID][x]];
            x ++;
        }

    }

    function ExecuteProposal(uint ProposalID) public {

        require(ProposalApproved[Proposal[ProposalID]] = true, "This proposal has not been approved by the DAO yet");
        VoteContract(Proposal[ProposalID]).Execute();
    }

    function approveToken(uint ProposalID, address WhatAddress, uint HowManyTokens, ERC20 token) public {

        require(ProposalApproved[Proposal[ProposalID]] && msg.sender == Proposal[ProposalID]);
        token.approve(WhatAddress, HowManyTokens);
    }
}
    
//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Contracts that this contract uses, contractception!     ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

interface VoteContract{
    function Execute() external;
}

interface ERC20{
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
    function decimals() external view returns (uint8);
    function approve(address, uint) external;
}
