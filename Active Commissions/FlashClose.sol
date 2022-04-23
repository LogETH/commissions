// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

// This contract unwraps fishy's loan

    // now to the code:

contract PrintMoney {

    // Settings that you can change before deploying

    constructor(){

        Fishy = msg.sender;
    }



//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////


    // ERC20 tokens

    ERC20 DAI  = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ERC20 FEI  = ERC20(0x956F47F50A910163D8BF957Cf5846D573E7f87CA);
    ERC20 TRIBE  = ERC20(0xc7283b66Eb1EB5FB86327f08e1B5816b0720212B);

    // fERC20 tokens

    Rari fTRIBE = Rari(0xFd3300A9a74b3250F1b2AbC12B47611171910b07);
    Rari fETH = Rari(0xbB025D470162CC5eA24daF7d4566064EE7f5F111);
    Rari fFEI = Rari(0xd8553552f8868C1Ef160eEdf031cF0BCf9686945);

    // DEXs

    Uniswap SWAP = Uniswap(0x7a250d5630b4cf539739df2c5dacb4c659f2488d);

    address Fishy;



//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    function unwrap(uint TRIBEprice, uint ETHprice, uint Slippage) public {

        require(msg.sender == Fishy, "You're not Fishy");

        TRIBE.approve(address(SWAP), uint(uint));

        while(fETH.borrowBalanceCurrent(address(this)) > 0){

        //  Step 1: Withdraw TRIBE, sell it for ETH, and pay back the loan.
        POOL.withdraw((POOL.balanceOf(address(this))*percentage/100));

        
        SWAP.swapExactTokensForTokens(TRIBE.balanceOf(address(this)));
        }

        while(fFEI.borrowBalanceCurrent(address(this)) > 0){

        //  Step 1: Withdraw TRIBE, sell it for ETH, and pay back the loan.
        POOL.withdraw((POOL.balanceOf(address(this))*percentage/100));


        }

        //  Step 1: Withdraw TRIBE, sell it for ETH, and pay back the loan.
        POOL.withdraw((POOL.balanceOf(address(this))*percentage/100));

        //  Step 2: Swap all LUSD for DAI
        LUSD3CRV.exchange_underlying(0, 1, LUSD.balanceOf(address(this)), (LUSD.balanceOf(address(this))*(Slippage/1000)));

        //  Step 3: Wrap DAI into cDAI and pay back the loan on rari.capital.
        DAI.approve(address(cDAI), DAI.balanceOf(address(this)));
        cDAI.mint(DAI.balanceOf(address(this)));
        cDAI.approve(address(fcDAI), cDAI.balanceOf(address(this)));

        // Step 3.5: If the percentage is 100%, pay off the entire loan using treasury reserves, if it isn't than just pay off what it can.
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

    function Sweep() public payable {

        (bool sent, bytes memory data) = Fishy.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
    
    //Emergency function that withdraws all of any token from this address to the DAO just in case something somehow goes wrong
    //or someone accidentally sends their life savings to this address

    function SweepToken(ERC20 Token) public payable {

        require(msg.sender == Fishy, "You're not Fishy");
        
        Token.transfer(Fishy, Token.balanceOf(address(this)));
    }


//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Internal and external functions this contract has:      ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////



// (msg.sender SHOULD NOT be used/assumed in any of these functions.)

    function CalcDepositLTV() internal returns(uint){

        // Desmos to make sure this equation works: https://www.desmos.com/calculator/auu4uxnmx3

        uint AvalBorrow;
        uint a;
        (a, AvalBorrow, a) = fcDAI.getAccountLiquidity(address(this));

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

        uint AvalBorrow;
        uint a;
        (a, AvalBorrow, a) = fcDAI.getAccountLiquidity(address(this));

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

interface ERC20{

    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
    function approve(address, uint256) external returns (bool success);
}

interface Uniswap {

    // 0x7a250d5630b4cf539739df2c5dacb4c659f2488d

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] memory path, uint deadline) external view returns (uint256);
    function deposit(uint256 lusdAmount) external;
    function withdraw(uint256 numShares) external;
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;

}
