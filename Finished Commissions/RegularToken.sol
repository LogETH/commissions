// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

//// What is this contract? 

//// This contract is an ERC20 token, literally just an ERC20 token with nothing special, that's it

//// Done by myself

contract RegularToken {

//// Before you deploy the contract, make sure to change these parameters to what you want

    constructor () {

        totalSupply = 1000000000 * 10e18;
        name = "Fake USDC";
        symbol = "fUSDC";

        balanceOf[msg.sender] = totalSupply; // You get all the total supply
        decimals = 18; // usually its 18 so its 18 here
    }

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    string public name;
    uint8 public decimals;
    string public symbol;
    uint public totalSupply;

    function transfer(address _to, uint256 _value) public returns (bool success) {

        require(balanceOf[msg.sender] >= _value, "You can't send more tokens than you have");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(balanceOf[_from] >= _value && allowance[_from][msg.sender] >= _value, "You can't send more tokens than you have or the approval isn't enough");

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
}
