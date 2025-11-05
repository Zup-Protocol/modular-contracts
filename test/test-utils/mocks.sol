// SPDX-License-Identifier: GNU GPLv3
// solhint-disable
pragma solidity 0.8.30;

import {IUniswapV3PositionManager} from "../../src/interfaces/IUniswapV3PositionManager.sol";

contract UniswapV3PositionManagerMock is IUniswapV3PositionManager {
    function mint(
        MintParams calldata params
    ) external payable override returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {}

    function refundETH() external payable override {}
}
