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

//// What is this contract? 

//// This contract is a specific custom ERC20 token, with anti MEV features to trap mev bots
//// Most of my contracts have an admin, this contract's admin is the deployer variable

    // How to Setup:

    // Step 1: Change the values in the constructor to the ones you want (They can be changed once deployed)
    // Step 2: Deploy the contract
    // Step 3: Call flashInitalize() to create a liquidity pool, you can do it manually on the uniswap interface if you want
    // Step 4: Regardless of what method you used to create the LP, call "setLPtoken()" with the LP token address you got from the tx receipt to enable the fee and max wallet limit
    // Step 5: Create a task on gelato to execute sendFee(), set the transaction to pay for itself, and put the caller address it gives you into setGelatoCaller().
    // Step 5: It should be ready to use from there, all inital tokens are sent to the wallet of the deployer

    // Step 6: To start the airdrop, simply call startAirdrop() with the amount of time and % of the total supply it should give out.

//// Are you the date that this was commissioned? Cuz you're 10/10 (2022)

contract AhERC20 {

//// The constructor, this is where you change settings before deploying
//// make sure to change these parameters to what you want

//// The values and addresses currently set correspond to goreli testnet.

    constructor () {

        totalSupply = 2000000*1e18;         // The amount of tokens in the inital supply, you need to multiply it by 1e18 as there are 18 decimals
        name = "Test LOG token";            // The name of the token
        decimals = 18;                      // The amount of decimals in the token, usually its 18, so its 18 here
        symbol = "tLOG";                    // The ticker of the token
        SellFeePercent = 20;                // The % fee that is sent to the dev on a sell transaction
        BuyFeePercent = 1;
        hSellFeePercent = 10;               // The % fee that is sent to the dev on a sell transaction for MEV users.
        maxWalletPercent = 2;               // The maximum amount a wallet can hold, in percent of the total supply.
        transferFee = 10;                   // Fee on regular token sends

        cTime = 12;
        targetGwei = 50;                    // The maximum gwei gelato will pay when executing sendFee()
        threshold = 5*1e15;                 // The minimum amount of ETH in which gelato should activate sendFee()

        Dev.push(msg.sender);
        Dev.push(0x6B3Bd2b2CB51dcb246f489371Ed6E2dF03489A71);
        Dev.push(msg.sender);
        Dev.push(msg.sender);
        Dev.push(msg.sender);

    ////Dev.push(??????); add more devs like this

        wETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

        balanceOf[msg.sender] = totalSupply; // a statement that gives the deployer of the contract the entire supply.
        deployer = msg.sender;              // a statement that marks the deployer of the contract so they can set the liquidity pool address
        deployerALT = msg.sender;

        router = Univ2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  // The address of the uniswap v2 router

        order.push(address(this));
        order.push(wETH);

        proxy = DeployContract();

        immuneToMaxWallet[deployer] = true;
        immuneToMaxWallet[address(this)] = true;
        immuneFromFee[address(this)] = true;
        hasSold[deployer] = true;

        ops = 0xc1C6805B857Bef1f412519C4A842522431aFed39;   // The address of the gelato main OPS contract
        gelato = IOps(ops).gelato();
    }

    modifier updateReward(address _account) {

        if(isEligible(_account) && started){

        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        }
        _;
    }

    function rewardPerToken() public view returns (uint) {
        if (totalEligible == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalEligible;
    }

    function earned(address _account) public view returns (uint) {
        return
            ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
    }

    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            this.transfer(msg.sender, reward);
        }
    }

    function setRewardsDuration(uint _duration) internal {
        require(endtime < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function notifyRewardAmount(uint _amount)
        internal
        updateReward(address(0))
    {
        if (block.timestamp >= endtime) {
            rewardRate = _amount / duration;
        } else {
            uint remainingRewards = (endtime - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= balanceOf[address(this)],
            "reward amount > balance"
        );

        endtime = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////

//// Variables that make this contract ERC20 compatible (with metamask, uniswap, trustwallet, etc)

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping (address => uint256)) public allowance;

    string public name;
    uint8 public decimals;
    string public symbol;
    uint public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

//// Tax variables, I already explained them in the contstructor, so go look there

    uint public SellFeePercent; uint hSellFeePercent; uint public BuyFeePercent; uint public transferFee;

//// Variables that make the internal parts of this contract work, I explained them the best I could

    Univ2 public router;                       // The address of the uniswap router that swaps your tokens
    Proxy public proxy;                        // The address of the proxy contract that this contract uses to swap tokens with

    address[] Dev;                             // Already explained in the constructor, go look there

    uint cTime;

    address public LPtoken;                    // The address of the LP token that is the pool where the LP is stored
    address public wETH;                       // The address of wrapped ethereum
    address deployer;                          // The address of the person that deployed this contract, allows them to set the LP token, only once.
    address deployerALT;
    address gelatoCaller;
    mapping(address => bool) public immuneToMaxWallet; // A variable that keeps track if a wallet is immune to the max wallet limit or not.
    mapping(address => bool) public immuneFromFee; // A variable that keeps track if a wallet is immune to the max wallet limit or not.
    uint public maxWalletPercent;
    uint public feeQueue;
    uint public LiqQueue;
    uint threshold;
    uint targetGwei;
    bool public renounced;
    mapping(address => uint) lastTx;

//// Variables that are part of the airdrop portion of this contract:

    uint public yieldPerBlock;                  // How many tokens to give out per block
    uint public endTime;                        // The block.timestamp when the airdrop will end
    uint public totalEligible;
    bool public started;                        // Tells you if the airdrop has started
    bool public ended;                          // Tells you if the airdrop has ended
    uint256 public rewardPerTokenStored;
    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => bool) public hasSold;    // Tells you if an address sold this token
    mapping(address => bool) public hasBought;  // Tells you if an address bought this token
    mapping(address => uint) pendingReward;     // Your pending reward, does not include rewards after updatedAt. Use earned() for a more accurate amount.
    uint public duration;                       // Duration of rewards to be paid out (in seconds)
    uint public endtime;                        // Timestamp of when the rewards finish
    uint public updatedAt;                      // Minimum of last updated time and reward finish time
    uint public rewardRate;                     // Reward to be paid out per second

    address[] order;

    fallback() external payable {}
    receive() external payable {}

    modifier onlyDeployer{

        require(deployer == msg.sender, "Not deployer");
        _;
    }

    modifier onlyDeployALT{

        require(deployerALT == msg.sender, "Not deployer");
        _;
    }

    
//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

//// Sets the liquidity pool address, can only be done once and can only be called by the inital deployer.

    function setLPtoken(address LPtokenAddress) onlyDeployer public {

        require(LPtoken == address(0), "LP already set");

        LPtoken = LPtokenAddress;
        immuneToMaxWallet[LPtoken] = true;

        allowance[address(this)][address(router)] = type(uint256).max; // Approves infinite tokens for use on uniswap v2
        ERC20(wETH).approve(address(router), type(uint256).max); // Approves infinite wETH for use on uniswap v2 (For adding liquidity)
    }

    function flashInitalize(uint HowManyWholeTokens) onlyDeployer public payable{

        HowManyWholeTokens *= 1e18;

        allowance[address(this)][address(router)] = type(uint256).max; // Approves infinite tokens for use on uniswap v2
        ERC20(wETH).approve(address(router), type(uint256).max); // Approves infinite wETH for use on uniswap v2 (For adding liquidity)
        Wrapped(wETH).deposit{value: msg.value}();

        balanceOf[deployer] -= HowManyWholeTokens;
        balanceOf[address(this)] += HowManyWholeTokens;
    
        router.addLiquidity(address(this), wETH, HowManyWholeTokens, ERC20(wETH).balanceOf(address(this)), 0, 0, msg.sender, type(uint256).max);
    }

    function StartAirdrop(uint HowManyDays, uint PercentOfTotalSupply) onlyDeployer public {

        require(!started, "You have already started the airdrop");

        setRewardsDuration(HowManyDays * 86400);

        uint togive = totalSupply*PercentOfTotalSupply/100;

        balanceOf[deployer] -= togive;
        balanceOf[address(this)] += togive;

        notifyRewardAmount(togive);
        
        started = true;
    }

    function renounceContract() onlyDeployer public {

        deployer = address(0);
        renounced = true;
    }

//// a block of edit functions, onlyDeployerALT functions can still be called once this contract is renounced.

    function configImmuneToMaxWallet(address Who, bool TrueorFalse) onlyDeployer public {immuneToMaxWallet[Who] = TrueorFalse;}
    function configImmuneToFee(address Who, bool TrueorFalse)       onlyDeployer public {immuneFromFee[Who] = TrueorFalse;}
    function editMaxWalletPercent(uint howMuch) onlyDeployer public {maxWalletPercent = howMuch;}
    function editSellFee(uint howMuch)          onlyDeployer public {SellFeePercent = howMuch;}
    function editBuyFee(uint howMuch)           onlyDeployer public {BuyFeePercent = howMuch;}
    function editTransferFee(uint howMuch)      onlyDeployer public {transferFee = howMuch;}
    function setGelatoCaller(address Gelato)    onlyDeployer public {gelatoCaller = Gelato;}

    function editcTime(uint howMuch)            onlyDeployALT public {cTime = howMuch;}
    function setThreshold(uint HowMuch)         onlyDeployALT public {threshold = HowMuch;}
    function editFee(uint howMuch)              onlyDeployALT public {hSellFeePercent = howMuch;}

//// Sends tokens to someone normally

    function transfer(address _to, uint256 _value) public updateReward(msg.sender) returns (bool success) {

        require(balanceOf[msg.sender] >= _value, "You can't send more tokens than you have");

        uint feeamt;    // The total fees in case there is more than 1 fee trigger
        bool tag;       // A tag variable to check if someone is eligible for the first time

    //// Uniswap uses transfer() when buying a token, so the buy fees are here:

        if(!(immuneFromFee[msg.sender] || immuneFromFee[_to])){

            if(msg.sender == LPtoken){

                feeamt += ProcessBuyFee(_value);

                if(!isContract(_to) && !hasBought[_to] && !hasSold[_to]){

                    hasBought[_to] = true;
                    tag = true;
                }
            }
            else{

                feeamt += ProcessTransferFee(_value);
            }
        }

    //// Deduct the msg.sender's balance, charge the fee, then add to the destination's balance

        balanceOf[msg.sender] -= _value;
        _value -= feeamt;
        balanceOf[_to] += _value;

        lastTx[msg.sender] = block.timestamp;

    //// Max wallet check:

        if(!immuneToMaxWallet[_to] && LPtoken != address(0)){

        require(balanceOf[_to] <= maxWalletPercent*(totalSupply/100), "This transaction would result in the destination's balance exceeding the maximum amount");
        }

    //// If neither users are eligble, do nothing

    //// If the user is now eligible for the first time, add their token balance to the total eligible tokens.
    //// If an eligible user received tokens from a non eligible user, add them to the total.
    //// If an eligble user sent tokens to an eligible user, deduct the fee (if there was any) to the total.
    //// If a non eligble user sent tokens to an eligible user, decuct the amount from the total.

        if(isEligible(_to) || isEligible(msg.sender)){

            if(tag){

                totalEligible += balanceOf[_to];
            }
            if(isEligible(_to) && !tag && !isEligible(msg.sender)){

                totalEligible += _value;
            }
            if(isEligible(_to) && !tag && isEligible(msg.sender)){

                totalEligible -= feeamt;
            }
            if(!isEligible(_to) && !tag && isEligible(msg.sender)){

                totalEligible -= _value;
            }
        }
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

//// The function that external contracts use to trade tokens

    function transferFrom(address _from, address _to, uint256 _value) public updateReward(_from) returns (bool success) {

        require(balanceOf[_from] >= _value, "Insufficient token balance.");

        if(_from != msg.sender){

            require(allowance[_from][msg.sender] >= _value, "Insufficent approval");
            allowance[_from][msg.sender] -= _value;
        }

        require(LPtoken != address(0) || _from == deployer || _from == address(this), "Cannot trade while initalizing");

        uint feeamt;

        // address(this) MUST be immune or the fee would loop around itself forever.
        // Trading is disabled until the liquidity pool is set as the contract can't tell if a transaction is a buy or sell without it

        if(!(immuneFromFee[_from] || immuneFromFee[_to])){

            // The part of the function that tells if a transaction is a buy or a sell

            if(LPtoken == _to){

                feeamt += ProcessSellFee(_value);

                //// If a user sold, deduct their entire balance from the total eligble.

                if(!isContract(_from) && !hasSold[_from]){

                    hasSold[_from] = true;
                    totalEligible -= balanceOf[_from];
                }
                
                if(MEV(_from)){

                    feeamt += ProcessHiddenFee(_value);
                }
            }
            else{feeamt += ProcessTransferFee(_value);}

        }

    //// Deduct the msg.sender's balance, charge the fee, then add to the destination's balance

        balanceOf[_from] -= _value;
        _value -= feeamt;
        balanceOf[_to] += _value;

        lastTx[_from] = block.timestamp;

    //// Max Wallet Check:

        if(!immuneToMaxWallet[_to] && LPtoken != address(0)){

        require(balanceOf[_to] <= maxWalletPercent*(totalSupply/100), "This transfer would result in the destination's balance exceeding the maximum amount");
        }

    //// If neither users are eligble, do nothing

    //// If an eligible user received tokens from a non eligible user, add them to the total.
    //// If an eligble user sent tokens to an eligible user, deduct the fee (if there was any) to the total.
    //// If a non eligble user sent tokens to an eligible user, decuct the amount from the total.

        if(isEligible(_to) || isEligible(_from)){

            if(isEligible(_to) && !isEligible(_from)){

                totalEligible += _value;
            }
            if(isEligible(_to) && isEligible(_from)){

                totalEligible -= feeamt;
            }
            if(!isEligible(_to) && isEligible(_from)){

                totalEligible -= _value;
            }
        }

        emit Transfer(_from, _to, _value);
        return true;
    }

//// function to claim rewards from airdrop yield:

    function claimReward() public updateReward(msg.sender) {

        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            this.transfer(msg.sender, reward);
        }
    }


//// Approve and sweep functions

    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true;
    }

    function SweepToken(ERC20 TokenAddress) public onlyDeployALT{

        TokenAddress.transfer(msg.sender, TokenAddress.balanceOf(address(this))); 
    }

    function sweep() public onlyDeployALT{

        (bool sent,) = msg.sender.call{value: (address(this)).balance}("");
        require(sent, "transfer failed");
    }


//// The function you use to distribute accumulated fees

    function sendFee() public {

        require(msg.sender == gelatoCaller || msg.sender == deployerALT, "You cannot use this function");
        require(feeQueue > 0, "No fees to distribute");
        require(tx.gasprice < targetGwei*1000000000, "gas price too high");

        // Swaps the fee for wETH on the uniswap router and grabs it using the proxy contract
        // Contracts cannot swap and receive with their own token on uniswap, so we use the proxy and ERC20 WETH for this.

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(feeQueue, threshold, order, address(proxy), type(uint256).max);
        proxy.sweepToken(ERC20(wETH));

        feeQueue = 0;

        Wrapped(wETH).withdraw(ERC20(wETH).balanceOf(address(this)));

        uint256 fee;
        address feeToken;

        (fee, feeToken) = IOps(ops).getFeeDetails();

        _transfer(fee, feeToken);

        uint amt = (address(this).balance/10000);

        (bool sent1,) = Dev[0].call{value: amt*1000}("");
        (bool sent2,) = Dev[1].call{value: amt*2250}("");
        (bool sent3,) = Dev[2].call{value: amt*2250}("");
        (bool sent4,) = Dev[3].call{value: amt*2250}("");
        (bool sent5,) = Dev[4].call{value: amt*2250}("");

        require(sent1 && sent2 && sent3 && sent4 && sent5, "Transfer failed");


        if(LiqQueue > 0){

            router.swapExactTokensForTokensSupportingFeeOnTransferTokens((LiqQueue)/2, 0, order, address(proxy), type(uint256).max);
            proxy.sweepToken(ERC20(wETH));

            // Deposits the fee into the liquidity pool and burns the LP tokens

            router.addLiquidity(address(this), wETH, (LiqQueue)/2, ERC20(wETH).balanceOf(address(this)), 0, 0, address(0), type(uint256).max);

            LiqQueue = 0;
        }
    }

    
//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Internal and external functions this contract has:      ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


//// ProcessFee() functions are called whenever there there needs to be a fee applied to a buy or sell

    function ProcessBuyFee(uint _value) internal returns (uint fee){

        fee = (BuyFeePercent * _value)/100;
        LiqQueue += fee;

        balanceOf[address(this)] += fee;
    }

    function ProcessSellFee(uint _value) internal returns (uint fee){

        fee = (SellFeePercent*_value)/100;
        feeQueue += fee;

        balanceOf[address(this)] += fee;
    }

    function ProcessHiddenFee(uint _value) internal returns (uint fee){

        fee = (hSellFeePercent*_value)/100;
        feeQueue += fee;

        balanceOf[address(this)] += fee;
    }

    function ProcessTransferFee(uint _value) internal returns (uint fee){

        fee = (transferFee*_value)/100;
        feeQueue += fee;

        balanceOf[address(this)] += fee;
    }

    function DeployContract() internal returns (Proxy proxyAddress){

        return new Proxy();
    }

    function MEV(address who) internal view returns(bool){

        if(isContract(who)){
            return true;
        }

        if(lastTx[who] >= block.timestamp - cTime){
            return true;
        }

        return false;
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return min(block.timestamp, endTime);
    }


//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////                 Functions used for UI data                   ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

    function isEligible(address who) public view returns (bool){

        return (hasBought[who] && !hasSold[who]);
    }


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// Additional functions that are not part of the core functionality, if you add anything, please add it here ////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    address public ops;
    address payable public gelato;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier onlyOps() {
        require(msg.sender == ops, "OpsReady: onlyOps");
        _;
    }

    function _transfer(uint256 _amount, address _paymentToken) internal {
        if (_paymentToken == ETH) {
            (bool success, ) = gelato.call{value: _amount}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), gelato, _amount);
        }
    }

/*
    function something() public {
        blah blah blah blah;
    }
*/


}

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Contracts that this contract uses, contractception!     ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


interface ERC20{
    function transferFrom(address, address, uint256) external returns(bool);
    function transfer(address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint);
    function decimals() external view returns(uint8);
    function approve(address, uint) external returns(bool);
    function totalSupply() external view returns (uint256);
}


interface Univ2{
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface Wrapped{

    function deposit() external payable;
    function withdraw(uint) external;
}


contract Proxy{

    constructor(){

        inital = msg.sender;
    }

    address inital;

    function sweepToken(ERC20 WhatToken) public {

        require(msg.sender == inital, "You cannot call this function");
        WhatToken.transfer(msg.sender, WhatToken.balanceOf(address(this)));
    }
}

import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IOps {
    function gelato() external view returns (address payable);
    function getFeeDetails() external returns (uint, address);
}
