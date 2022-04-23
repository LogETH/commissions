// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

// This contract unwraps fishy's loan

    // now to the code:

contract FlashClose {

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

    // Prices are in FEI.
    // input the price with 8 decimals
    // Ex: If TRIBE was 6.79 FEI, you would put in 679000000

    // Slippage has 1 decimal, for 0.5% slippage, input "5".

    function unwrap(uint TRIBEprice, uint ETHprice, uint Slippage) public {

        require(msg.sender == Fishy, "You're not Fishy");

        TRIBE.approve(address(SWAP), uint(uint)); // Approve the MAX amount possible to swap on uniswap

        while(fFEI.borrowBalanceCurrent(Fishy) > 0){

            //  Step 1: Withdraw TRIBE, sell it for FEI, and pay back the loan.
            fTRIBE.transferFrom(Fishy, address(this), CalcWithdrawLTV(ETHprice));
            fTRIBE.redeem(CalcWithdrawLTV(ETHprice));
        
            SWAP.swapExactTokensForTokens(TRIBE.balanceOf(address(this)), CalcTRIBEPrice(TRIBEprice, Slippage), 
            address[TRIBE][FEI], uint(uint));

            fFEI.repayBorrowBehalf(Fishy, FEI.balanceOf(address(this)));
        }

        while(fETH.borrowBalanceCurrent(address(this)) > 0){

            //  Step 1: Withdraw TRIBE, sell it for FEI, and pay back the loan.
            fETH.redeem(CalcWithdrawLTV(ETHprice));


        }

        require(GetCurrentLTV() < 50, "Something went wrong");
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

    function CalcBorrowLTV() internal returns(uint){

        // Desmos to make sure this equation works: https://www.desmos.com/calculator/auu4uxnmx3

        uint AvalBorrow;
        (AvalBorrow) = fTRIBE.getAccountLiquidity(address(this));

        uint FULL = fcDAI.borrowBalanceCurrent(address(this)) + AvalBorrow;
        uint CurrentLTV = (FULL/fcDAI.borrowBalanceCurrent(address(this)))*100;

        uint x = 74-CurrentLTV;
        require(CurrentLTV < 74, "Your deposit is not enough to peg the LTV at the target %, try depositing a higher amount");

        AvalBorrow *= (uint(x)/100);

        return AvalBorrow;
    }

    function CalcWithdrawLTV(uint ETHprice) internal returns(uint){

        // Desmos to make sure this equation works: https://www.desmos.com/calculator/auu4uxnmx3
        // (Yes its the same thing)

        uint AvalBorrow;
        (,AvalBorrow,) = fFEI.getAccountLiquidity(address(this));

        uint FULL = fFEI.borrowBalanceCurrent(address(this)) + (CalcETHPrice(fETH.borrowBalanceCurrent(address(this))*(fETH.exchangeRateCurrent()/10**18), ETHprice) + AvalBorrow);
        uint CurrentLTV = (FULL/fETH.borrowBalanceCurrent(address(this)))*100;

        uint x = 74-CurrentLTV;
        require(CurrentLTV < 74, "Your withdraw is not enough to peg the LTV at the target %, try withdrawing a higher amount or 100%");

        uint AvalWithdraw = fFEI.balanceOf(address(this)) * (uint(x)/100);

        return AvalWithdraw;

    }

    function GetCurrentLTV() internal returns(uint){

        // Desmos to make sure this equation works: https://www.desmos.com/calculator/auu4uxnmx3
        // (Yes its the same thing)

        (,uint AvalBorrow,) = fTRIBE.getAccountLiquidity(address(this));

        uint FULL = fTRIBE.borrowBalanceCurrent(address(this)) + AvalBorrow;
        uint CurrentLTV = (FULL/fTRIBE.borrowBalanceCurrent(address(this)))*100;

        return CurrentLTV;

    }

    function CalcTRIBEPrice(uint TRIBEprice,uint ETHprice, uint Slippage) internal returns (uint){

        return (TRIBE.balanceOf(address(this))*TRIBEprice*ETHprice)(Slippage/1000);
    }

    function CalcETHPrice(uint ETHprice, uint Slippage) internal returns (uint){

        return (TRIBE.balanceOf(address(this))*(TRIBEprice/10^8)*(ETHprice/10**8))(Slippage/1000);
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
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint)
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

}

interface UniswapV3 {

    // 0xE592427A0AEce92De3Edee1F18E0157C05861564

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] memory path, uint deadline) external view returns (uint256);
    function deposit(uint256 lusdAmount) external;
    function withdraw(uint256 numShares) external;
    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;

}
