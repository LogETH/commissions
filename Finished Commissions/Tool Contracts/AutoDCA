// SPDX-License-Identifier: CC-BY-SA 4.0
//https://creativecommons.org/licenses/by-sa/4.0/

// TL;DR: The creator of this contract (@LogETH) is not liable for any damages associated with using the following code
// This contract must be deployed with credits toward the original creator, @LogETH.
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests I endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the license.

// By deploying this contract, you agree to the license above and the terms and conditions that come with it.

pragma solidity >=0.8.0 <0.9.0;

contract AutoDCA {

//// This contract lets you to buy a token automatically every day off of uniswap v3 like a DCA bot on an exchange

    // How to setup the contract:

        // Step 1: Configure the settings in the constructor below and deploy the contract
        // Step 2: Manually approve USDC for use on this contract
        // Step 3: Go to gelato and create a task to call buyETH() whenever it can
        // Step 4: You should be good, make sure to refill gas on gelato every once in awhile

//// Done by myself (@LogETH on github)

    // the constructor that activates when you deploy the contract, this is where you change settings before deploying.
    // The default settings are for the polygon (MATIC) network.

    // If you're using a different token in this contract than the default ones, you may have to change the amount of decimals in getPrice() used to calculate the price of it.

    constructor() {
        
        admin = msg.sender;                                                     // Makes the deployer of this contract the admin

        router = Uniswap(0xE592427A0AEce92De3Edee1F18E0157C05861564);           // The address of uniswap's router, which is used to buy wETH
        oracle = Chainlink(0xF9680D99D6C9589e2a93a78A04A279e509205945);         // The address of chainlink's oracle, so this contract knows the best price to buy at

        USDC = ERC20(0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359);               // The address of USDC
        wETH = ERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);               // The address of wETH

        buyAmount = 6 *1e6;                                                     // Unlike most tokens, USDC has six decimals
        cooldownLength = 1 days;                                                // How often this contract should buy

        targetGwei = 80;                                                       // The max gas price this contract will allow to be used to buy

        USDC.approve(address(router), type(uint256).max);                       // Approves infinite USDC for trade on the uniswap router
    }

//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////


//// Special Variables go here:

    ERC20 public USDC;                              // The address of USDC
    ERC20 public wETH;                              // The address of wETH
    Uniswap public router;                          // The address of the uniswap router
    Chainlink public oracle;                        // The address of the chainlink oracle

//// All the Variables that this contract uses

    address public immutable admin;                 // The admin of this contract, cannot be changed once set
    uint256 public buyAmount;                       // The amount of USDC this contract should spend per buy interval
    uint256 public targetGwei;                      // The max gas price this contract wil allow to be used when buying
    uint256 public cooldownLength;                  // How long the buying cooldown of this contract is
    uint256 lastTx;                                 // Internal variable to track when was the last time this contract bought
    bool reentry;                                   // Internal variable to prevent reentrancy
    bool public paused;                             // Variable to know if this contract is paused or not

//// Modifiers

    // Functions with "cooldown" have a cooldown when being used, all functions share the same cooldown

    modifier cooldown(){

        require(lastTx + cooldownLength < block.timestamp, "Cooldown in progress");
        _;
        lastTx = block.timestamp;
    }

    // Functions with "OnlyAdmin" are only allowed to be used by the admin

    modifier onlyAdmin(){

        require(msg.sender == admin, "Not Authorized");
        _;
    }

    // Functions with "pausable" are able to be paused if needed with the pause() function

    modifier pausable(){

        require(paused == false, "Paused");
        _;
    }

    // Functions with "nonReentrant" are not allowed to be used while a transaction is happening

    modifier nonReentrant{
        require(!reentry, "Reentrant");
        reentry = true;
        _;
        reentry = false;
    }

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

//// Put visible functions (Buttons that people press) here:

    function buyETH() public cooldown pausable nonReentrant{

        // Prevents the TX from going through if gas is too expensive
        require(tx.gasprice < targetGwei * 1000000000, "gas price too high");

        // Gets USDC from the admin
        USDC.transferFrom(admin, address(this), buyAmount);

        // encode the parameters
        Uniswap.ExactInputSingleParams memory params = Uniswap
            .ExactInputSingleParams({
                tokenIn: address(USDC),                 // Address of the input token (The one you want to sell)
                tokenOut: address(wETH),                // Address of the output token (The one you want to buy)
                fee: 500,                               // The fee of the pool you want to buy from (in basis points x100)
                recipient: admin,                       // The address where the bought tokens go to
                deadline: block.timestamp,              // The deadline for the trade to complete, block.timestamp = now
                amountIn: buyAmount,                    // The amount to buy
                amountOutMinimum: getPrice(),           // The minimum you should get or uniswap will revert
                sqrtPriceLimitX96: 0                    // idk what this does but setting it to zero disables it
            });

        // buy ETH using the admin's USDC and send it to the admin of this contract
        router.exactInputSingle(params); 
    }

    // Functions in case there is a token or ETH stuck in this contract and you need to get it out

    function sweep() public {
        (bool sent, ) = admin.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function sweepToken(ERC20 Token) public {
        Token.transfer(admin, Token.balanceOf(address(this)));
    }


//// Admin functions to change settings of this contract

    // Changes the max gas price this contract will accept

    function changeTargetGwei(uint newTargetGwei) public onlyAdmin{

        targetGwei = newTargetGwei;
    }

    // Gives you the ability to pause the contract if needed

    function pause(bool trueOrFalse) public onlyAdmin{

        paused = trueOrFalse;
    }

    // Lets you change the cooldown of how often this contract buys

    function changeCooldownTime(uint newCooldownTime) public onlyAdmin {

        cooldownLength = newCooldownTime;
    }

    // Lets you change the amount this contract buys every interval

    function changeBuyAmount(uint newBuyAmount) public onlyAdmin{

        buyAmount = newBuyAmount;
    }

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Internal and external functions this contract has:      ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

//// Put internal functions here: (There should NOT be any msg.sender or tx.origin in here)

    // getPrice() should return how much "buyAmount" is currently worth in wei
    // price is 8 decimals, ETH has 18 decimals

    function getPrice() public view returns(uint ETHamount) {

        (,int price,,,) = oracle.latestRoundData();

        // this should result in the value having as many decimals as the token this contract is buying (In this case, 18 since the token is wETH)
        // If you change the tokens from their default ones, you may have to change this to it equals it

        ETHamount = (buyAmount*1e20)/uint(price); 
    }

}

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Contracts that this contract uses, contractception!     ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


interface ERC20 {
    function transferFrom(address,address,uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
    function approve(address, uint) external;
}

interface Uniswap {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

interface Chainlink {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}
