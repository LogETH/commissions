// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract FeeDistributor{

    ERC20 DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address Log = 0x4D9aA2Aac04Ce1Ba557D6008b28210F4187930A2;
    address Fishy = 0x72b7448f470D07222Dbf038407cD69CC380683F3; // Put your address here.


    function claim() public{

        //Sends half to Log and half to Fishy, callable by anyone.

        DAI.transfer(Log, DAI.balanceOf(address(this))/2);
        DAI.transfer(Fishy, DAI.balanceOf(address(this))/2);
    }

    //Edits the address rewards are sent to, you cannot set it to an empty address or the burn address.

    function EditAddress(address Who) public {

        require(msg.sender == Log || msg.sender == Fishy);
        require(Who != address(0), "No. Please don't do that.");
        require(Who.balance > 0, "This address has no ether/no transaction history, are you sure thats the right address?");

        if(msg.sender == Log){Log = Who;}
        if(msg.sender == Fishy){Fishy = Who;}
    }

    //If this address receives ETH somehow, this function can be used to claim it

    function Sweep() public payable {

        (bool sent, bytes memory data) = Log.call{value: address(this).balance/2}("");
        (bool sent2, bytes memory data2) = Fishy.call{value: address(this).balance/2}("");
        require(sent && sent2, "Failed to send Ether");

    }
    
    //If this address receives a token other than DAI, this function can be used to claim it

    function SweepToken(ERC20 Token) public payable {

        require(Token != DAI);
        
        Token.transfer(Log, Token.balanceOf(address(this))/2);
        Token.transfer(Fishy, Token.balanceOf(address(this))/2);
    }

    function CheckClaimableBalance() public view returns(uint) {

        return DAI.balanceOf(address(this));
    }


}

interface ERC20{

    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
}
