// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract FeeDistributor{

    ERC20 DAI = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address Log = 0x4D9aA2Aac04Ce1Ba557D6008b28210F4187930A2;
    address Fishy = 0x72b7448f470D07222Dbf038407cD69CC380683F3;


    function claim() public{

        //Sends half to Log and half to Fishy, callable by anyone.

        uint half = DAI.balanceOf(address(this))/2;

        DAI.transfer(Log, half);
        DAI.transfer(Fishy, half);
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

        uint half = address(this).balance/2;

        (bool sent,) = Log.call{value: half}("");
        (bool sent2,) = Fishy.call{value: half}("");
        require(sent && sent2, "Failed to send Ether");

    }
    
    //If this address receives a token other than DAI, this function can be used to claim it

    function SweepToken(ERC20 Token) public payable {

        uint half = Token.balanceOf(address(this))/2;
        
        Token.transfer(Log, half);
        Token.transfer(Fishy, half);
    }

    function CheckClaimableBalance() public view returns(uint) {

        return DAI.balanceOf(address(this));
    }


}

interface ERC20{

    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
}
