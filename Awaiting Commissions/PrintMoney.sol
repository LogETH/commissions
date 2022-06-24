// SPDX-License-Identifier: CC-BY-SA 4.0
// https://creativecommons.org/licenses/by-sa/4.0/

// TL;DR: The creator of this contract (@LogETH) is not liable for any damages associated with using the following code
// This contract must be deployed with credits toward the original creator, @LogETH.
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests I endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the license.

// You may not deploy this contract without a signature displaying "[address] has permission to deploy PrintMoney.sol" generated from coinlog.eth

// By deploying this contract, you agree to the license above and the terms and conditions that come with it.

pragma solidity >=0.7.0 <0.9.0;

// This contract is a yield strategy for FEI dao.

    // Here are the steps to success:

    // 1) Borrow cDAI off of FEI from rari.capital        
    // 2) Unwrap cDAI to DAI using Compound
    // 3) Swap DAI to LUSD using Curve.fi
    // 4) Deposit LUSD into the liquity stability pool

// IMPORTANT:
// In order for this contract to work, the tokens FEI, BAMM, and cDAI must be approved for use on this contract.
// The FEI/cDAI rari market must also be intialized with sufficent liquidity before this contract is deployed

    // now to the code:

abstract contract PrintMoney {

    // Settings that you can change before deploying

    constructor(){

        DAO = 0xd51dbA7a94e1adEa403553A8235C302cEbF41a3c;
        Slippage = 995; //Translates to 0.5% slippage for swapping DAI to LUSD and vise versa.
        LTV = 80; //Translates to 80% target LTV for the cDAI loan.

        //Of course I probably don't have to tell you this, but please don't preset the LTV >99% since that would break everything lol...
        //(Don't even think about it... i'm watching you.)
    }



//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////



    // ERC20 tokens

    ERC20 DAI  = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ERC20 FEI  = ERC20(0x956F47F50A910163D8BF957Cf5846D573E7f87CA);
    ERC20 LUSD = ERC20(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0);
    ERC20 LQTY = ERC20(0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D);

    // cERC20 and fcERC20 tokens

    Comp cDAI  = Comp(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    Rari fcDAI = Rari(0x0000000000000000000000000000000000000000); // Replace with the actual fcDAI address please.
    Rari fcFEI = Rari(0x0000000000000000000000000000000000000000); // Replace with the actual fcFEI address pretty please.

    // Curve swapping thingy

    Curve LUSD3CRV = Curve(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA); 

    // Liquity stability pool

    StbPool POOL = StbPool(0x0d3AbAA7E088C2c82f54B2f47613DA438ea8C598);

    address DAO;
    uint public Slippage;
    uint public LTV;



//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////



    function deposit(uint amount) public {

        require(msg.sender == DAO, "Only the DAO can execute this function, not you dummy...");

        //  Step 1: Deposit FEI into rari.capital.
        FEI.transferFrom(msg.sender, address(this), amount);
        FEI.approve(address(fcFEI), amount);
        fcFEI.mint(amount);

        //  Step 2: Borrow cDAI at the target LTV and unwrap it.
        fcDAI.borrow(CalcDepositLTV());
        cDAI.redeem(cDAI.balanceOf(address(this)));

        //  Step 3: Swap DAI to LUSD on Curve.fi
        LUSD3CRV.exchange_underlying(1, 0, DAI.balanceOf(address(this)), (Slippage*(DAI.balanceOf(address(this))/1000)));

        //  Step 4: Deposit all LUSD held by this address into the LUSD stability pool
        POOL.deposit(LUSD.balanceOf(address(this)));
    }

    function withdraw(uint percentage) public {

        require(msg.sender == DAO, "Only the DAO can execute this function, not you dummy...");

        //  Step 1: Withdraw LUSD and LQTY rewards from the stability pool
        POOL.withdraw((POOL.balanceOf(address(this))*percentage/100));

        //  Step 2: Swap all LUSD for DAI
        LUSD3CRV.exchange_underlying(0, 1, LUSD.balanceOf(address(this)), Slippage*((LUSD.balanceOf(address(this))/1000)));

        //  Step 3: Wrap DAI into cDAI and pay back the loan on rari.capital.
        DAI.approve(address(cDAI), DAI.balanceOf(address(this)));
        cDAI.mint(DAI.balanceOf(address(this)));
        cDAI.approve(address(fcDAI), cDAI.balanceOf(address(this)));

        // Step 3.5: If the percentage is 100%, pay off the loan using treasury reserves, if it isn't than just pay off what it can.
        if(percentage == 100){
            cDAI.transferFrom(DAO, address(this), (fcDAI.borrowBalanceCurrent(address(this))-cDAI.balanceOf(address(this))));
            fcDAI.repayBorrow(fcDAI.borrowBalanceCurrent(address(this)));
        }
        else{fcDAI.repayBorrow(cDAI.balanceOf(address(this)));}

        // Step 4: Withdraw enough FEI to keep the LTV at the target amount and return FEI and earned LQTY to the DAO treasury.
        if(percentage == 100){
            fcFEI.redeem(fcFEI.balanceOf(address(this)));
            FEI.transfer(DAO, FEI.balanceOf(address(this)));
        }

        else {
            fcFEI.redeem(CalcWithdrawLTV());
            FEI.transfer(DAO, FEI.balanceOf(address(this)));
        }

        LQTY.transfer(DAO, LQTY.balanceOf(address(this)));
    }
    
    function EditLTV(uint TargetLTV) public {

        require(msg.sender == DAO, "Only the DAO can execute this function, not you dummy...");
        require(TargetLTV <= 99, "You can't set the target LTV to 100% or higher, that would break this contract");
        LTV = TargetLTV;
    }

    function EditSlippage(uint TargetSlippage) public {

        require(msg.sender == DAO, "Only the DAO can execute this function, not you dummy...");
        require(TargetSlippage <= 50, "You can't set the slippage to over 5%, you will get front run when swapping and lose a shit ton of money.");
        Slippage = TargetSlippage;
    }

    // Anyone can call claimRewards to transfer any available LQTY rewards to the DAO

    function claimRewards() public {

        POOL.withdraw(0);
        LQTY.transfer(DAO, LQTY.balanceOf(address(this)));
    }

    // Sweep any excess ETH from this address to the DAO address, anyone can call it
    // I know the compiler can flag this as yellow but thats fine

    // Remember, if its yellow, keep it mellow, if its red, bash your head.

    function Sweep() public payable {

        (bool sent,) = DAO.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
    
    //Emergency function that withdraws all of any token from this address to the DAO just in case something somehow goes wrong
    //or someone accidentally sends their life savings to this address

    function SweepToken(ERC20 Token) public payable {

        require(msg.sender == DAO, "Only the DAO can execute this function, not you dummy...");
        
        Token.transfer(DAO, Token.balanceOf(address(this)));
    }


//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Internal and external functions this contract has:      ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////



// (msg.sender SHOULD NOT be used/assumed in any of these functions.)

    // Big math function (this took a while to figure out)
    // This function calculates how much cDAI to borrow or FEI to withdraw to peg the LTV at the set amount
    //
    // FULL = Maximum Borrow Balance
    // LTV = Target LTV
    // CurrentLTV = The current LTV ratio
    // x = How much we have to raise or lower the LTV to reach the target amount.
    // If its impossible to reach the LTV with the contract's current funds, the function reverts.

    function CalcDepositLTV() internal returns(uint){

        // Desmos to make sure this equation works: https://www.desmos.com/calculator/auu4uxnmx3

        (, uint AvalBorrow,) = fcDAI.getAccountLiquidity(address(this));

        uint FULL = fcDAI.borrowBalanceCurrent(address(this)) + AvalBorrow;
        uint CurrentLTV = (FULL/fcDAI.borrowBalanceCurrent(address(this)))*100;

        uint x = LTV-CurrentLTV;
        require(CurrentLTV < LTV, "Your deposit is not enough to peg the LTV at the target %, try depositing a higher amount");

        AvalBorrow *= (uint(x)/100);

        return AvalBorrow;
    }

    function CalcWithdrawLTV() internal returns(uint){

        // Desmos to make sure this equation works: https://www.desmos.com/calculator/auu4uxnmx3
        // (Yes its the same thing)

        (, uint AvalBorrow,) = fcDAI.getAccountLiquidity(address(this));

        uint FULL = fcDAI.borrowBalanceCurrent(address(this)) + AvalBorrow;
        uint CurrentLTV = (FULL/fcDAI.borrowBalanceCurrent(address(this)))*100;

        uint x = LTV-CurrentLTV;
        require(CurrentLTV < LTV, "Your withdraw is not enough to peg the LTV at the target %, try withdrawing a higher amount or 100%");

        uint AvalWithdraw = fcFEI.balanceOf(address(this)) * (uint(x)/100);

        return AvalWithdraw;

    }
}

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Contracts that this contract uses, contractception!     ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


interface Rari{

    // Rari Dev Docs https://docs.rari.capital/fuse/#general
    function mint(uint) external returns (uint);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function balanceOf(address) external view returns(uint);
    function getAccountLiquidity(address account) external returns (uint, uint, uint);
    function borrowBalanceCurrent(address account) external returns (uint);
}

interface Curve{

    function exchange_underlying(int128, int128, uint256, uint256) external;
}

interface Comp {

    // Comp dev docs https://medium.com/compound-finance/supplying-assets-to-the-compound-protocol-ec2cf5df5aa#afff
    function mint(uint256) external returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function supplyRatePerBlock() external returns (uint256);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function approve(address, uint256) external returns (bool success);
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
}

interface ERC20{

    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
    function approve(address, uint256) external returns (bool success);
}

interface StbPool {

    // IBAMM Interface https://github.com/fei-protocol/fei-protocol-core/blob/develop/contracts/pcv/liquity/IBAMM.sol

    function balanceOf(address account) external view returns (uint256);
    function deposit(uint256 lusdAmount) external;
    function withdraw(uint256 numShares) external;
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;

}
