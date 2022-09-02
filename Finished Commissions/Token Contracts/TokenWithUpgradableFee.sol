// SPDX-License-Identifier: CC-BY-SA 4.0
//https://creativecommons.org/licenses/by-sa/4.0/

// TL;DR: The creator of this contract (@LogETH) is not liable for any damages associated with using the following code
// This contract must be deployed with credits toward the original creator, @LogETH.
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests I endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the license.

// By deploying this contract, you agree to the license above and the terms and conditions that come with it.

pragma solidity >=0.7.0 <0.9.0;

//// What is this contract? 

//// This contract is an ERC20 token that can be customized once its deployed using external contracts

//// Done by myself on 8/14/2022

contract TokenWithUpgradableFee {

//// Before you deploy the contract, make sure to change these parameters to what you want

    constructor () {

        balances[msg.sender] = 2000000*10**18;
        totalSupply = 2000000*10**18;
        name = "LOG token";
        decimals = 18;
        symbol = "LOG";

        admin = msg.sender;
    }

////

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    string public name;
    uint8 public decimals;
    string public symbol;
    uint public totalSupply;
    mapping(address => bool) public ImmuneFromFee;
    address public admin;
    uint nonce;
    mapping(uint => FeeProxy) public fee;

    modifier onlyAdmin{

        require(msg.sender == admin, "You aren't the admin so you can't press this button!");
        _;
    }

    function ExcludeFromFee(address Who) public onlyAdmin{

        ImmuneFromFee[Who] = true;
    }

    function IncludeFromFee(address Who) public onlyAdmin{

        ImmuneFromFee[Who] = false;
    }

    function addFee(address FeeContract) public onlyAdmin {

        fee[nonce] = FeeProxy(FeeContract);
        nonce ++;
    }

    function removeFee(uint FeeID) public onlyAdmin {

        fee[FeeID] = FeeProxy(address(0));
    }

    function ProcessFee(uint _value, address _payee) internal returns (uint){

        uint x;

        while(x <= nonce){

            // Low level call so it doesn't revert if it fails.

            (, bytes memory returnData) = address(fee[x]).call(abi.encodePacked(fee[x].process.selector,abi.encode(_value, _payee)));

            uint returnedAmount = abi.decode(returnData, (uint256));
            _value -= returnedAmount;

            x ++;
        }

        return _value;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {

        require(balances[msg.sender] >= _value, "You can't send more tokens than you have");

        if(ImmuneFromFee[_to] == true || ImmuneFromFee[msg.sender] == true){}
        else{_value = ProcessFee(_value, msg.sender);}

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value, "You can't send more tokens than you have or the approval isn't enough");

        if(ImmuneFromFee[_to] == true || ImmuneFromFee[_from] == true){}
        else{_value = ProcessFee(_value, _from);}

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {

        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {

        return allowed[_owner][_spender];
    }
}

interface FeeProxy{

    function process(uint, address) external returns (uint);
}
