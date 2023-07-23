// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
interface IShortTermFund {
    function deposit(address _token, uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function requestWithdraw(uint256 _amount) external;

    function startTrade() external payable;

    function closeTrade() external;

    function checkUpKeep(
        bytes calldata checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData);

    function performUpKeep(bytes calldata performData) external;

    function init(
        string memory _stratergyName,
        string memory _stratergySymbol,
        address _vault,
        address _module,
        address _trader,
        address _oracle,
        address _investmentToken,
        address _router,
        address _positionRouter,
        uint256 _fee
    ) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function _mint(address account, uint256 amount) external;

    function _burn(address account, uint256 amount) external;

    function _approve(address owner, address spender, uint256 amount) external;
}
