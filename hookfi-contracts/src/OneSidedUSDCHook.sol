// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract OneSidedUSDCHook is BaseHook {
    address public immutable token; // Newly issued token (e.g., MTK from Flaunch)
    address public immutable usdc; // USDC address on Base
    address public immutable creator; // Creator's address for token reserve
    PoolKey public poolKey;
    mapping(address => bool) public isLiquidityProvider; // Tracks LPs

    constructor(
        IPoolManager _poolManager,
        address _token,
        address _usdc,
        address _creator
    ) BaseHook(_poolManager) {
        token = _token;
        usdc = _usdc;
        creator = _creator;
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: true,
            beforeAddLiquidity: false,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: true,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function afterInitialize(
        address,
        PoolKey calldata key,
        uint160 sqrtPriceX96,
        int24
    ) external override returns (bytes4) {
        poolKey = key;
        return BaseHook.afterInitialize.selector;
    }

    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        BalanceDelta delta,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(poolManager), "Only PoolManager can call");
        require(key.currency0 == token && key.currency1 == usdc, "Invalid pool pair");

        // Decode USDC amount from data
        (uint256 usdcAmount) = abi.decode(data, (uint256));

        // Calculate required token amount based on pool's price
        uint256 tokenAmount = calculateTokenAmount(usdcAmount, key);

        // Source tokens from creator's reserve
        require(IERC20(token).balanceOf(creator) >= tokenAmount, "Insufficient creator tokens");
        IERC20(token).transferFrom(creator, address(this), tokenAmount);
        IERC20(token).approve(address(poolManager), tokenAmount);

        // Add liquidity to the pool
        poolManager.modifyLiquidity(key, int256(usdcAmount), int256(tokenAmount), address(this));

        // Mark sender as LP
        isLiquidityProvider[sender] = true;

        return BaseHook.afterAddLiquidity.selector;
    }

    function afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1,
        BalanceDelta delta,
        bytes calldata
    ) external override returns (bytes4) {
        // Remove LP status if no liquidity remains (simplified check)
        isLiquidityProvider[sender] = false;
        return BaseHook.afterRemoveLiquidity.selector;
    }

    function beforeSwap(
        address sender,
        PoolKey calldata key,
        bool swapForY,
        int256 amountSpecified,
        bytes calldata
    ) external override returns (bytes4) {
        require(isLiquidityProvider[sender], "Only LPs can swap");
        return BaseHook.beforeSwap.selector;
    }

    function calculateTokenAmount(uint256 usdcAmount, PoolKey calldata key) internal view returns (uint256) {
        // Simplified: Use pool's sqrtPriceX96 to calculate token amount
        // In practice, query Uniswap v4's price curve or an oracle
        return usdcAmount * 100; // Example: 1 USDC = 100 tokens (adjust based on price)
    }
}
