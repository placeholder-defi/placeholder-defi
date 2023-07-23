// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IOneInchHandler {
  function swap(
    address sellTokenAddress,
    address buyTokenAddress,
    uint sellAmount,
    bytes memory callData,
    address _to
  ) external payable;

  function setAllowance(address _token, address _spender, uint _sellAmount) external;
}
