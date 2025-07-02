// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMorphoBlue {
    function supply(address asset, uint256 amount) external;
    function borrow(address asset, uint256 amount) external;
    function withdraw(address asset, uint256 amount) external;
    function repay(address asset, uint256 amount) external;
}

contract ElevationFlashLoanBot is FlashLoanSimpleReceiverBase {
    address public owner;
    address public morpho;
    address public elevationWallet;

    constructor(
        address _provider,
        address _morpho,
        address _elevationWallet
    ) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_provider)) {
        owner = msg.sender;
        morpho = _morpho;
        elevationWallet = _elevationWallet;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // Step 1: Supply borrowed USDC to Morpho
        IMorphoBlue(morpho).supply(asset, amount);

        // Step 2: Borrow back from Morpho (by default 75% LTV)
        uint256 borrowAmount = (amount * 75) / 100;
        IMorphoBlue(morpho).borrow(asset, borrowAmount);

        // Step 3: (Optional) Send profit to charity – implemented outside for clarity

        // Step 4: Repay Morpho: first repay borrowed amount, then withdraw supply
        IMorphoBlue(morpho).repay(asset, borrowAmount);
        IMorphoBlue(morpho).withdraw(asset, amount);

        // Step 5: Repay Aave flash loan
        uint256 totalOwed = amount + premium;
        IERC20(asset).approve(address(POOL), totalOwed);

        return true;
    }

    function triggerFlashLoan(address asset, uint256 amount) external onlyOwner {
        POOL.flashLoanSimple(address(this), asset, amount, "", 0);
    }

    function updateElevationWallet(address newWallet) external onlyOwner {
        elevationWallet = newWallet;
    }

    function withdrawERC20(address token) external onlyOwner {
        IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
    }
}
