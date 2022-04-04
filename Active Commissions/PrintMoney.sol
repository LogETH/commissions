// SPDX-License-Identifier: MIT

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

contract PrintMoney {

    // Settings that you can change before deploying

    constructor(){

        DAO = 0x0000000000000000000000000000000000000000; //Input FEI DAO address
        Slippage = 995; //Translates to 0.5% slippage for swapping DAI to LUSD and vise versa.
        LTV = 80; //Translates to 80% target LTV for the cDAI loan.
    }

//                                        //
//// Variables that this contract uses: ////
//                                        //

    // ERC20 tokens

    ERC20 DAI  = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    ERC20 FEI  = ERC20(0x956F47F50A910163D8BF957Cf5846D573E7f87CA);
    ERC20 LUSD = ERC20(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0);
    ERC20 USDT = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    ERC20 LQTY = ERC20(0x0000000000000000000000000000000000000000); // Replace with the actual LQTY address please.

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

//                                                //
//// Visible Functions that this contract uses: ////
//                                                //

    function deposit(uint amount) public {

        require(msg.sender == DAO, "Only the DAO can execute this function, not you dummy...");

    //  Step 1: Deposit FEI into rari.capital.
        FEI.transferFrom(msg.sender, address(this), amount);
        FEI.approve(address(fcFEI), amount);
        fcFEI.mint(amount);

    //  Step 2: Borrow cDAI at the target LTV and unwrap it.
        uint AvalBorrow;
        uint a;
        (a, AvalBorrow, a) = fcDAI.getAccountLiquidity(address(this));
        fcDAI.borrow((AvalBorrow-(CalcLTV(AvalBorrow))));
        cDAI.redeem(cDAI.balanceOf(address(this)));

    //  Step 3: Swap DAI to LUSD on Curve.fi
        LUSD3CRV.exchange_underlying(1, 0, DAI.balanceOf(address(this)), (DAI.balanceOf(address(this))*(Slippage/1000)));

    //  Step 4: Deposit all LUSD held by this address into the LUSD stability pool
        POOL.deposit(LUSD.balanceOf(address(this)));
    }

        // Sweep any excess ETH from this address to the DAO address, anyone can call it

    function Sweep() public payable {

        (bool sent, bytes memory data) = DAO.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

        // Anyone can call claimRewards to transfer any LQTY rewards to the DAO

    function claimRewards() public {

        POOL.withdraw(0);
        LQTY.transfer(DAO, LQTY.balanceOf(address(this)));
    }

    function withdraw(uint percentage) public {

        require(msg.sender == DAO, "Only the DAO can execute this function, not you dummy...");

    //  Step 1: Withdraw LUSD and LQTY rewards from the stability pool
        POOL.withdraw((POOL.balanceOf(address(this))*percentage/100));

    //  Step 2: Swap all LUSD for DAI
        LUSD3CRV.exchange_underlying(0, 1, LUSD.balanceOf(address(this)), (LUSD.balanceOf(address(this))*(Slippage/1000)));

    //  Step 3: Wrap DAI into cDAI and pay back the loan on rari.capital.
        DAI.approve(address(cDAI), DAI.balanceOf(address(this)));
        cDAI.mint(DAI.balanceOf(address(this)));
        cDAI.approve(address(fcDAI), cDAI.balanceOf(address(this)));

        // Step 3.5: If the percentage is 100%, pay off the loan using treasury reserves, if it isn't than just pay off what it can.

        if(percentage == 100){

            cDAI.transferFrom(DAO, address(this), (fcDAI.borrowBalanceCurrent(address(this))-cDAI.balanceOf(address(this))));
            fcDAI.repayBorrow(fcDAI.borrowBalanceCurrent(address(this)));
        }
        
        else{

            fcDAI.repayBorrow(cDAI.balanceOf(address(this)));
        }

    // Step 4: Withdraw enough FEI to keep the LTV at the target amount and return it to the DAO treasury.

        // im going to have to use some complex math equation to calculate this.. one sec

        if(percentage == 100){

            fcFEI.redeem(fcFEI.balanceOf(address(this)));
            FEI.transfer(DAO, FEI.balanceOf(address(this)));
        }

        else{

        uint AvalBorrow;
        uint a;
        (a, AvalBorrow, a) = fcDAI.getAccountLiquidity(address(this));

        uint FULL = fcDAI.borrowBalanceCurrent(address(this)) + AvalBorrow;

        FULL = FULL - FULL/LTV;

        uint amount = FULL - fcDAI.borrowBalanceCurrent(address(this)) + AvalBorrow;

        fcFEI.redeemUnderlying(amount);

        FEI.transfer(DAO, FEI.balanceOf(address(this)));

        }
    }
    
    function EditLTV(uint TargetLTV) public {

        require(msg.sender == DAO, "Only the DAO can execute this function, not you dummy...");
        require(TargetLTV <= 99, "You can't set the target LTV to 100% or higher, that would break this contract");
        LTV = TargetLTV;
    }

    function EditSlippage(uint TargetSlippage) public {

        require(msg.sender == DAO, "Only the DAO can execute this function, not you dummy...");
        require(TargetSlippage <= 99, "You can't set the slippage to 5%");
        Slippage = TargetSlippage;
    }


// Internal and External Functions this contract uses:
// (msg.sender SHOULD NOT be used/assumed in any of these functions.)

    function CalcLTV(uint AvalBorrow) internal view returns(uint){


        int iLTV = int(LTV) - 100;
        uint uLTV = uint(iLTV*-1);

        AvalBorrow = AvalBorrow*(uLTV/100);

        return AvalBorrow;
    }

}

//// Contracts that this contract uses, contractception!

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

    function fetchPrice() external view returns (uint256);

    /// @notice returns amount of ETH received for an LUSD swap
    function getSwapEthAmount(uint256 lusdQty) external view returns (uint256 ethAmount, uint256 feeEthAmount);

    /// @notice Liquity Stability Pool Address
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);

    /// @notice Reward token
    function bonus() external view returns (address);

    // Mutative Functions

    /// @notice deposit LUSD for shares in BAMM
    function deposit(uint256 lusdAmount) external;

    /// @notice withdraw shares  in BAMM for LUSD + ETH
    function withdraw(uint256 numShares) external;

    function transfer(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external;

}

// Stability Pool Interface Ref: https://github.com/fei-protocol/fei-protocol-core/blob/develop/contracts/pcv/liquity/IStabilityPool.sol
