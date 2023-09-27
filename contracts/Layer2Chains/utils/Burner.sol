// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;

interface IERC20Burnable {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

contract Burner{
    function burnERC20(address ERC20Contract, uint256 amount) internal{
        IERC20Burnable(ERC20Contract).burn(amount);
    }

}