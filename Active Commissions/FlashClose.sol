// SPDX-License-Identifier: MIT

// TL;DR: You are free to use this however you want, edit however you want, and integrate however you want
// I (@LogETH) am not responsible for any damages that may happen from use of this contract.

pragma solidity >=0.7.0 <0.9.0;

// This contract unwinds any leveraged loan on any COMP based B/L platform like Compound.finance, Tranquil.finance, Market.xyz, and Rari.capital in a single click
// Works on all chains and all forks of compound. No need for oracles or flash loans. Only a uniswap V2 fork like pancakeswap or whatever you have on your preferred chain.

    // How to setup and use (Super Easy):

//  1) Fill in the constructor below with the tokens and uniswap V2 router you would like to use
//  2) Compile and deploy the contract on your preferred blockchain 
//  3) Approve the collateral token for use on this contract
//  4) Press unwrap() and you're done!

//  All the error messages I put in should tell you what is wrong if something goes wrong

    // now to the code:

abstract contract FlashClose {

    // Settings that you change before deploying

    constructor(){

        you = msg.sender; //You are you.
        SWAP = Uniswap(0x0000000000000000000000000000000000000000); // Change this to the uniswap V2 fork router that's on the chain you use.

        Collat = ERC20(0x0000000000000000000000000000000000000000); // The ERC20 token you are using as collateral.
        Borrow = ERC20(0x0000000000000000000000000000000000000000); // The ERC20 token you are borrowing.

        cCollat = Rari(0x0000000000000000000000000000000000000000); // The compound receipt token of the Collateral token.
        cBorrow = Rari(0x0000000000000000000000000000000000000000); // The compound receipt token of the Borrowed token.

        LTV = 0; // Set this to the MAX LTV minus 1, for example, if the max LTV is 80, set this to 79.

        require(SWAP != address(0), "You need to put the uniswap V2 router address in the constructor settings before you deploy!");
        require(Borrow != address(0), "You need to put the collateral token address in the constructor settings before you deploy!");
        require(Collat != address(0), "You need to put the borrowed token address in the constructor settings before you deploy!");
    }


//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////

    // (You don't change this)

    // ERC20 tokens

    ERC20 Collat; // The token you are using as collateral
    ERC20 Borrow; // The token you are borrowing.

    // fERC20 tokens

    Rari cCollat; // The receipt token you get as proof you deposited your collateral
    Rari cBorrow; // The receipt token that allows you to pay back your debt.

    // DEXs

    Uniswap SWAP; // Your preferred Uniswap V2 router.

    address you; // This is you 



//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

    // Prices are in terms of your collateral token.
    // input the price with 8 decimals
    // Ex: If TRIBE was 6.79 FEI, you would put in 679000000

    // Slippage has 1 decimal, for 0.5% slippage, input "5".
    // If you don't know what slippage is go look up how to use a dex on google please

    function unwrap(uint TRIBEprice, uint ETHprice, uint Slippage) public {

        require(msg.sender == you, "You're not you");

        TRIBE.approve(address(SWAP), uint(uint)); // Approve the MAX amount possible to swap on uniswap

        while(cBorrow.borrowBalanceCurrent(you) > 0){

            //  Step 1: Withdraw the token you're lending, sell it for the borrowed token, and pay back your debt.
            cCollat.transferFrom(you, address(this), CalcWithdrawLTV(ETHprice));
            cCollat.redeem(CalcWithdrawLTV(ETHprice));

            //  Step 2: Swap Collat for Borrow.
            SWAP.swapExactTokensForTokens(TRIBE.balanceOf(address(this)), CalcCollatPrice(TRIBEprice, Slippage), 
            address[Collat][Borrow], uint(uint));

            //  Step 3: Pay back your debt
            cBorrow.repayBorrowBehalf(you, Borrow.balanceOf(address(this)));

            //  Step 4: Repeat until your debt is zero.
        }

        require(GetCurrentLTV() < 50, "Something went wrong");
    }

    //  Functions that give you control over this address, sweep sends any gas token held by this contract to you
    //  and sweep token lets you claim any token balance this contract has

    function Sweep() public payable {

        (bool sent, bytes memory data) = you.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function SweepToken(ERC20 Token) public payable {

        require(msg.sender == you, "You're not you");
        
        Token.transfer(you, Token.balanceOf(address(this)));
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

        (,uint AvalBorrow,) = cCollat.getAccountLiquidity(address(this));

        uint FULL = cCollat.borrowBalanceCurrent(address(this)) + AvalBorrow;
        uint CurrentLTV = (FULL/cCollat.borrowBalanceCurrent(address(this)))*100;

        return CurrentLTV;

    }

    function CalcCollatPrice(uint Collatprice,uint Borrowprice, uint Slippage) internal returns (uint){

        return (Collat.balanceOf(address(this))*Collatprice*Borrowprice)(Slippage/1000);
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
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
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
