// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IPositionRouter {
    function increasePositionRequestKeysStart() external view returns (uint256);
    function decreasePositionRequestKeysStart() external view returns (uint256);
    function increasePositionRequestKeys(uint256 index) external view returns (bytes32);
    function decreasePositionRequestKeys(uint256 index) external view returns (bytes32);
    function executeIncreasePositions(uint256 _count, address payable _executionFeeReceiver) external;
    function executeDecreasePositions(uint256 _count, address payable _executionFeeReceiver) external;
    function getRequestQueueLengths() external view returns (uint256, uint256, uint256, uint256);
    function getIncreasePositionRequestPath(bytes32 _key) external view returns (address[] memory);
    function getDecreasePositionRequestPath(bytes32 _key) external view returns (address[] memory);
function createIncreasePosition(
    address[] memory _path,
    address _indexToken,
    uint _amountIn,
    uint _minOut,
    uint _sizeDelta,
    bool _isLong,
    uint _acceptablePrice,
    uint _executionFee,
    bytes32 _referralCode,
    address _callbackTarget
  ) external payable returns (bytes32);

  function createDecreasePosition(
    address[] memory _path,
    address _indexToken,
    uint _collateralDelta,
    uint _sizeDelta,
    bool _isLong,
    address _receiver,
    uint _acceptablePrice,
    uint _minOut,
    uint _executionFee,
    bool _withdrawETH,
    address _callbackTarget
  ) external payable returns (bytes32);

   function minExecutionFee() external view returns (uint);
}