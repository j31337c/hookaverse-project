// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";
import {OneSidedUSDCHook} from "./OneSidedUSDCHook.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract OneClickUSDCFactory {
    // Immutable reference to Uniswap v4 PoolManager
    IPoolManager public immutable poolManager;
    
    // USDC address on Base (Mainnet or Sepolia)
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    
    // CREATE2 deployer address (standard on Ethereum/Base)
    address public constant CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0b4956C;

    // Event emitted when a pool is created
    event PoolCreated(
        address indexed token,
        address indexed hook,
        bytes32 indexed poolId
    );

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
    }

    /**
     * @notice Deploys a custom hook and initializes a token/USDC pool
     * @param token The address of the newly issued token (from HookFi)
     * @param fee The pool fee (e.g., 3000 for 0.3%)
     * @param sqrtPriceX96 The initial square root price for the pool
     * @param creator The address holding token reserves for one-sided liquidity
     * @return hook The deployed hook contract address
     * @return poolId The ID of the created pool
     */
    function deployHookAndPool(
        address token,
        uint24 fee,
        uint160 sqrtPriceX96,
        address creator
    ) external returns (address hook, bytes32 poolId) {
        // Validate inputs
        require(token != address(0), "Invalid token address");
        require(creator != address(0), "Invalid creator address");
        require(fee > 0, "Invalid fee");

        // Deploy hook with CREATE2 to ensure correct permissions
        uint160 flags = uint160(
            Hooks.AFTER_INITIALIZE_FLAG |
            Hooks.AFTER_ADD_LIQUIDITY_FLAG |
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.AFTER_REMOVE_LIQUIDITY_FLAG
        );
        bytes memory constructorArgs = abi.encode(poolManager, token, USDC, creator);
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER,
            flags,
            type(OneSidedUSDCHook).creationCode,
            constructorArgs
        );

        // Deploy the hook contract
        OneSidedUSDCHook hookContract = new OneSidedUSDCHook{salt: salt}(
            poolManager,
            token,
            USDC,
            creator
        );
        require(address(hookContract) == hookAddress, "Hook address mismatch");

        // Determine pool pair order (token < USDC or USDC < token)
        address currency0 = token < USDC ? token : USDC;
        address currency1 = token < USDC ? USDC : token;

        // Create PoolKey
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: fee,
            hooks: hookContract,
            parameters: bytes32(0)
        });

        // Initialize the pool
        poolId = PoolIdLibrary.toId(key);
        poolManager.initialize(key, sqrtPriceX96);

        // Emit event
        emit PoolCreated(token, address(hookContract), poolId);

        return (address(hookContract), poolId);
    }

    /**
     * @notice Helper function to get the expected hook address (for frontend verification)
     * @param token The token address
     * @param creator The creator address
     * @return hookAddress The expected hook address
     */
    function getExpectedHookAddress(
        address token,
        address creator
    ) external view returns (address hookAddress) {
        uint160 flags = uint160(
            Hooks.AFTER_INITIALIZE_FLAG |
            Hooks.AFTER_ADD_LIQUIDITY_FLAG |
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.AFTER_REMOVE_LIQUIDITY_FLAG
        );
        bytes memory constructorArgs = abi.encode(poolManager, token, USDC, creator);
        (hookAddress,) = HookMiner.find(
            CREATE2_DEPLOYER,
            flags,
            type(OneSidedUSDCHook).creationCode,
            constructorArgs
        );
    }
}
