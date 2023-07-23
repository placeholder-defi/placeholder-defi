// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {SafeERC20Upgradeable, IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract OneInchHandler is Initializable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMathUpgradeable for uint;

  IPriceOracle internal oracle;
  address internal swapTarget;

  function init(address _swapTarget, address _oracle) external initializer {
    swapTarget = _swapTarget;
    oracle = IPriceOracle(_oracle);
  }

  function swap(
    address sellTokenAddress,
    address buyTokenAddress,
    uint256 sellAmount,
    bytes memory callData,
    address _to
  ) public payable {
    uint256 tokenBalance = IERC20Upgradeable(sellTokenAddress).balanceOf(address(this));
    require(tokenBalance >= sellAmount,"Insufficient Fund");

    uint256 _currentAllowance = IERC20Upgradeable(sellTokenAddress).allowance(address(this), swapTarget);
    if (_currentAllowance != sellAmount) {
      IERC20Upgradeable(sellTokenAddress).safeDecreaseAllowance(swapTarget, _currentAllowance);
      IERC20Upgradeable(sellTokenAddress).safeIncreaseAllowance(swapTarget, sellAmount);
    }

    uint256 tokensBefore = IERC20Upgradeable(buyTokenAddress).balanceOf(address(this));
    (bool success, ) = swapTarget.call(callData);
    require(success,"Swap Failed");
    uint256 tokensSwapped = 0;

    uint buyTokenBalance = IERC20Upgradeable(buyTokenAddress).balanceOf(address(this));

    tokensSwapped = buyTokenBalance - tokensBefore;
    require(tokensSwapped > 0,"Zero Token Swapped");

    TransferHelper.safeTransfer(buyTokenAddress, _to, IERC20Upgradeable(buyTokenAddress).balanceOf(address(this)));
  }

  receive() external payable {}
}
