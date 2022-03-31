// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract PrintMoney {

    constructor(){

        DAO = //Input FEI DAO address
    }

    // This contract is a yield stratagy for FEI dao.

    // Here are the steps to success:

    // 1) Deposit cDAI into Rari.capital 
    // 2) Borrow cDAI off of FEI from rari.capital
    // 3) Unwrap cDAI to DAI using Compound
    // 4) Swap DAI to LUSD using Curve.fi
    // 5) Deposit LUSD into the liquity stability pool

    // This contract zaps this yield stratagy instantly in one transaction.
    // it can also reverse the entire stratagy or a percentage of it in one transaction.

    // Variables this contract uses:
    address DAO; // FEI dao

    // Visible Functions this contract has:

    // Internal and External Functions this contract uses:
    // (msg.sender SHOULD NOT be used in any of these functions.)


}

//// Contracts that this contract uses, contractception!

interface rari{


}

interface curve{



}
