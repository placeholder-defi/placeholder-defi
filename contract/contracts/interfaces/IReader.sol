pragma solidity 0.8.16;

interface IReader {
    function getPositions(address _vault, address _account, address[] memory _collateralTokens, address[] memory _indexTokens, bool[] memory isLong) external returns(uint[] memory);
}