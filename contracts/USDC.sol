// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDCToken is ERC20 {
    /// @notice Constrcutor of Test USDC Token
    /// @param initialSupply The initial total supply of USDC Token
    constructor(uint256 initialSupply) ERC20("USD Coin", "USDC") {
        _mint(msg.sender, initialSupply * 10 ** 6);
    }

    /// @notice Mint USDC Token
    /// @param account The account to mint USDC Token
    /// @param amount The amount to mint USDC Token
    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    /// @notice Burn USDC Token
    /// @param account The account to burn USDC Token
    /// @param amount The amount to burn USDC Token
    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }
}
