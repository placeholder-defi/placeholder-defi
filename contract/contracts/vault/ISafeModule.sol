// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface ISafeModule {

  /// @dev Initialize function, will be triggered when a new proxy is deployed
  /// @param initializeParams Parameters of initialization encoded
  function setUp(bytes memory initializeParams) external;

  function executeWallet(address handlerAddresses, bytes calldata encodedCalls) external returns (bool isSuccess);
}
