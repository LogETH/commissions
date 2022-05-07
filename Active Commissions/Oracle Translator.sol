// SPDX-License-Identifier: CC-BY-SA 4.0
// https://creativecommons.org/licenses/by-sa/4.0/

// TL;DR: The creator of this contract (@LogETH) is not liable for any damages associated with using the following code
// This contract must be deployed with credits toward the original creator, @LogETH.
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests I endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the license.

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
