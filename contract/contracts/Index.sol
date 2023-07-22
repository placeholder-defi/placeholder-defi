// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IPositionRouter.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IReader.sol";
import "hardhat/console.sol";
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";

contract TokenBase is ERC20Burnable, Ownable, ReentrancyGuard {
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}
}

contract Index is TokenBase {
    using SafeMath for uint;

    IPriceOracle public oracle;
    IRouter public router;
    IPositionRouter public positionRouter;
    IReader public reader;
    address constant vault_GMX = 0x489ee077994B6658eAfA855C308275EAd8097C4A;

    constructor(string memory _name, string memory _symbol, address _priceOracle, address _router, address _positionRouter, address _reader)
    TokenBase(_name, _symbol){
        oracle = IPriceOracle(_priceOracle);
        router = IRouter(_router);
        positionRouter = IPositionRouter(_positionRouter);
        reader = IReader(_reader);
    }

    function _getTokenPriceETHUSD(uint256 amount)
        public
        view
        returns (uint256 amountInBNB)
    {
        amountInBNB = oracle.getEthUsdPrice(amount);
    }

    function invest(uint _tokenAmount, address _token) public {
        require(_tokenAmount != 0);
        TransferHelper.safeTransferFrom(_token,msg.sender,address(this),_tokenAmount);
        _mint(msg.sender, _tokenAmount);
    }

    function tradeGMX(address _inputToken,address[] memory _path, address _indexToken, uint _amountIn , bool _isLong, bytes32 _referralCode, address _callbackTarget) public payable{
        router.approvePlugin(address(positionRouter));
        TransferHelper.safeApprove(_inputToken,address(router),_amountIn);
        uint executionFee = positionRouter.minExecutionFee();

        uint priceETH = oracle.getNormalizedRate(_indexToken, _inputToken).mul(1000000000000000000).mul(10**12);
        uint sizeDelta = oracle.getNormalizedRate(_inputToken,address(0x0000000000000000000000000000000000000348)).mul(_amountIn).mul(10**12);
        // positionRouter.createIncreasePosition{value: msg.value}(_path, _indexToken, _amountIn, 0, _amountIn.mul(10**30), _isLong, _getTokenPriceETHUSD(1000000000000000000).mul(10**30), positionRouter.minExecutionFee(), _referralCode, _callbackTarget);
        positionRouter.createIncreasePosition{value: executionFee}(_path, _indexToken, _amountIn, 0, sizeDelta , _isLong, priceETH, executionFee, _referralCode, _callbackTarget);
      
    }

    function getPositions(address[] memory _colateralTokens, address[] memory _indexTokens, bool[] memory isLong) public returns(uint256[] memory) {
        uint256[] memory position;
        position = reader.getPositions(vault_GMX, address(this), _colateralTokens, _indexTokens, isLong);
        return position;
    }

    // function closeGMX()

}