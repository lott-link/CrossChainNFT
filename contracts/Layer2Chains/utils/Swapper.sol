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

// on polygon matic mainnet
contract Swapper {

    ISwapRouter internal constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IV3Factory internal constant factory = IV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    IpegSwap internal constant pegSwap = IpegSwap(0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b);
    address internal constant wMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address internal constant LINK_ERC20 = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;
    address internal constant LINK_ERC677 = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    address internal constant LOTT = 0x773ADb3F75c4754aE1A56FfF3ad199056817bEAE;

    // For this example, we will set the pool fee to 0.3%.
    uint24 internal constant poolFee = 3000;

// MATIC - LOTT ---------------------------------------------------------------------

    function swap_MATIC_LOTT(
        uint256 amountIn
    ) internal returns(uint256 amountOut) {
        IwERC20(wMATIC).deposit{value: amountIn}();

        TransferHelper.safeApprove(wMATIC, address(swapRouter), amountIn);

        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(wMATIC, poolFee, LINK_ERC20, poolFee, LOTT),
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0
            });

        amountOut = swapRouter.exactInput(params);
    }


// LINK - LOTT ---------------------------------------------------------------------

    function swap_LINK677_LOTT(
        uint256 amountIn
    ) internal returns(uint256 amountOut) {
        swap_LINK677_20(amountIn);

        TransferHelper.safeApprove(LINK_ERC20, address(swapRouter), amountIn);

        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(LINK_ERC20, poolFee, LOTT),
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0
            });

        amountOut = swapRouter.exactInput(params);
    }

    function swap_LINK677_20(uint256 amount) internal {
        TransferHelper.safeApprove(LINK_ERC677, address(pegSwap), amount);
        pegSwap.swap(amount, LINK_ERC677, LINK_ERC20);
    }
    
    receive() external payable{}
}