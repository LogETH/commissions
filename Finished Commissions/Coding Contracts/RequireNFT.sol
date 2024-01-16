pragma solidity >=0.7.0 <0.9.0;

    // Enables the "RequireNFT" modifier which requires an NFT to use a function

contract RequireNFT{

    address NFT;

    modifier requireNFT{

        require(ERC721(NFT).balanceOf(msg.sender) != 0 || NFT = address(0), "You do not have the right NFT in order to use this contract");
        _;
    }
}

interface ERC721{
    function balanceOf(address) external returns (uint);
}
