// SPDX-License-Identifier: CC-BY-SA 4.0

//// This calculator is used to find an appropriate "StakeFactor/RewardsFactor" in NFTStakingUpgradable.sol and NFTRegisterRewardDistribution.sol
//// This calculator is only required for those 2 contracts, any new contracts that I code will already have this calculator integrated into it.

pragma solidity >=0.7.0 <0.9.0;

contract calculator{

    function TestMath(uint TokensPerBlockPerNFT, uint HowManyBlocks, uint decimals) public pure returns(uint) {

        uint Value = TokensPerBlockPerNFT * (10**decimals);
        TokensPerBlockPerNFT = Value/HowManyBlocks;
        return TokensPerBlockPerNFT;
    }
}
