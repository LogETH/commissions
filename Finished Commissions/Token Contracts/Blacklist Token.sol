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

//// This contract is a token that has several modules attached to it
//// Modules in this contract: Blacklist.

//// Commissioned by ICΛRUS 𝐗𝐈𝐈𝐈#9110 **Scammer who did not pay me**

contract TokenWithBlacklist {

//// Before you deploy the contract, make sure to change these parameters to what you want

    constructor () {

        totalSupply = 1000000000   *1e18; // has to be multiplied by 1e18 because 18 decimals
        name = "Log Token";
        decimals = 18;
        symbol = "LOG";

        admin = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////


    mapping(address => bool) public Blacklist;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    string public name;
    address public admin;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    modifier onlyAdmin{

        require(msg.sender == admin, "You aren't the admin so you can't press this button!");
        _;
    }

    modifier blacklist(address _from, address _to){

        require(!Blacklist[_from] && !Blacklist[_to], "Your or the destination's address is blacklisted");
        _;
    }


//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    function EditBlacklist(address who, bool TrueOrFalse) public onlyAdmin{Blacklist[who] = TrueOrFalse;}

    function transfer(address _to, uint256 _value) public blacklist(msg.sender, _to) returns(bool success) {

        require(balanceOf[msg.sender] >= _value, "You can't send more tokens than you have");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public blacklist(_from, _to) returns (bool success) {

        require(balanceOf[_from] >= _value && allowance[_from][msg.sender] >= _value, "You can't send more tokens than you have or the approval isn't enough");

        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public blacklist(msg.sender, msg.sender) returns (bool success) {

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true;
    }
}
