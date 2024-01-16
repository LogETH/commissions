// SPDX-License-Identifier: MIT

// By deploying this contract, you agree to the license above and the terms and conditions that come with it.

pragma solidity >=0.7.0 <0.9.0;

// Turns an oracle output into a simple "getPrice()" function

contract OracleTranslator {

    Chainlink Oracle = Chainlink(0x0000000000000000000000000000000000000000); // Put the chainlink oracle here.

    // Price must return 8 decimals

    function getPrice() public returns (uint){

        (,int price,,,) = Oracle.latestRoundData();
        
        return uint(price);
    }
}
interface Chainlink{

    // Chainlink Dev Docs https://docs.chain.link/docs/
    function latestRoundData() external returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}
