pragma solidity >=0.7.0 <0.9.0;

    // Enables the "takeFee" modifier which takes a tax to use a function

contract TakeFee{

    uint txCost;
    address[] path;

    modifier takeFee{

        require(msg.value == txCost, "msg.value is not txCost");
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(0, path, treasury, type(uint).max);
        _;
    }
}

interface Univ2{
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
}
