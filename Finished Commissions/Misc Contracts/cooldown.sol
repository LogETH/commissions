pragma solidity >=0.7.0 <0.9.0;

    // Enables the "cooldown" modifier which enforces a cooldown to use a function

contract Cooldown{

    uint duration;
    mapping(address => uint) lastTx;

    modifier cooldown{

        require(lastTx[msg.sender] + duration < block.timestamp, "Your Locking time has not finished yet.");
        _;
        lastTx[msg.sender] = block.timestamp;
    }
}
