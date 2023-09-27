// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

interface IwERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function balanceOf(address _owner) external view returns(uint256);
}

interface IV3Factory {
    function getPool(address token0, address token1, uint24 fee) external view returns(address);
}

interface IpegSwap {
    function swap(uint256 amount, address source, address target) external;
}

interface IV3PairPool {
    struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        // the current protocol fee for token0 and token1,
        // 2 uint32 values store in a uint32 variable (fee/PROTOCOL_FEE_DENOMINATOR)
        uint32 feeProtocol;
        // whether the pool is locked
        bool unlocked;
    }
    function slot0() external view returns(Slot0 memory);
    function token0() external view returns(address);
    function token1() external view returns(address);
}

library pricer {
    
    function getPrice0(uint256 sqrtPriceX96) internal pure returns(uint256) {
        uint256 denom = ((2 ** 96) ** 2);
        denom /= 10 ** 18;
        return (sqrtPriceX96 ** 2) / denom;
    }

    function getPrice1(uint256 sqrtPriceX96) internal pure returns(uint256) {
        uint256 denom = (sqrtPriceX96 ** 2) / 10 ** 18;
        return ((2 ** 96) ** 2) / denom;
    }
}

// on polygon matic mainnet
contract Swapper {
    using pricer for uint160;

    ISwapRouter internal constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IV3Factory internal constant factory = IV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    IpegSwap internal constant pegSwap = IpegSwap(0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b);
    address internal constant wMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address internal constant LINK_ERC20 = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;
    address internal constant LINK_ERC677 = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    address internal constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address internal constant LOTT = 0x773ADb3F75c4754aE1A56FfF3ad199056817bEAE;

    // For this example, we will set the pool fee to 0.3%.
    uint24 internal constant poolFee = 3000;

    function USDT_MATIC() public view returns(uint256) {
        IV3PairPool pool = IV3PairPool(factory.getPool(wMATIC, USDT, poolFee));
        (uint160 sqrtPriceX96) = pool.slot0().sqrtPriceX96;
        return pool.token0() == wMATIC ? sqrtPriceX96.getPrice1() : sqrtPriceX96.getPrice0();
    }

    function MATIC_USDT() public view returns(uint256) {
        IV3PairPool pool = IV3PairPool(factory.getPool(wMATIC, USDT, poolFee));
        (uint160 sqrtPriceX96) = pool.slot0().sqrtPriceX96;
        return pool.token0() == wMATIC ? sqrtPriceX96.getPrice0() : sqrtPriceX96.getPrice1();
    }

    function USDT_LINK() public view returns(uint256) {
        IV3PairPool pool = IV3PairPool(factory.getPool(LINK_ERC20, USDT, poolFee));
        (uint160 sqrtPriceX96) = pool.slot0().sqrtPriceX96;
        return pool.token0() == LINK_ERC20 ? sqrtPriceX96.getPrice1() : sqrtPriceX96.getPrice0();
    }

    function LINK_USDT() public view returns(uint256) {
        IV3PairPool pool = IV3PairPool(factory.getPool(LINK_ERC20, USDT, poolFee));
        (uint160 sqrtPriceX96) = pool.slot0().sqrtPriceX96;
        return pool.token0() == LINK_ERC20 ? sqrtPriceX96.getPrice0() : sqrtPriceX96.getPrice1();
    }

    function LOTT_LINK() public view returns(uint256) {
        IV3PairPool pool = IV3PairPool(factory.getPool(LINK_ERC20, LOTT, poolFee));
        (uint160 sqrtPriceX96) = pool.slot0().sqrtPriceX96;
        return pool.token0() == LINK_ERC20 ? sqrtPriceX96.getPrice1() : sqrtPriceX96.getPrice0();
    }

    function LINK_LOTT() public view returns(uint256) {
        IV3PairPool pool = IV3PairPool(factory.getPool(LINK_ERC20, LOTT, poolFee));
        (uint160 sqrtPriceX96) = pool.slot0().sqrtPriceX96;
        return pool.token0() == LINK_ERC20 ? sqrtPriceX96.getPrice0() : sqrtPriceX96.getPrice1();
    }

    function LOTT_USDT() public view returns(uint256) {
        return LOTT_LINK() * LINK_USDT() / 10 ** 18;
    }

    function USDT_LOTT() public view returns(uint256) {
        return USDT_LINK() * LINK_LOTT() / 10 ** 18;
    }

// MATIC - LOTT ---------------------------------------------------------------------

    function swap_MATIC_LOTT(
        uint256 amountIn
    ) internal returns(uint256 amountOut) {
        IwERC20(wMATIC).deposit{value: amountIn}();

        TransferHelper.safeApprove(wMATIC, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: wMATIC,
                tokenOut: LOTT,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }


// LINK - LOTT ---------------------------------------------------------------------

    function swap_LINK677_LOTT(
        uint256 amountIn
    ) internal returns(uint256 amountOut) {
        swap_LINK677_20(amountIn);

        TransferHelper.safeApprove(LINK_ERC20, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: LINK_ERC20,
                tokenOut: LOTT,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }

    function swap_LINK677_20(uint256 amount) internal {
        pegSwap.swap(amount, LINK_ERC677, LINK_ERC20);
    }
    receive() external payable{}
}