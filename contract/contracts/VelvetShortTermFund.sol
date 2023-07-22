// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IPriceOracle.sol";
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import {IVelvetSafeModule} from "./vault/IVelvetSafeModule.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract VelvetShortTermFund is Ownable, ERC20 {
    using SafeMath for uint256;

    bool private isTradeEnabled;
    address private vault;
    address private investmentToken;
    address private index;
    uint256 private fee;
    uint256 private lastTrade;
    uint256 private lastUpKeep;
    IPriceOracle private oracle;
    IVelvetSafeModule private safe;

    struct WithdrawRequest {
        address user;
        uint256 amount;
    }

    WithdrawRequest[] internal requestArray;

    uint256 internal constant PERCENTAGE = 10_000;

    event Deposit(address indexed user, uint256 amount, uint256 tokenMinted);
    event Withdraw(
        address indexed user,
        uint256 amount,
        uint256 tokenBurned,
        uint256 balanceReceived
    );
    event TradeStarted(address indexed user);
    event TradeClosed(address indexed user);

    constructor(
        string memory _stratergyName,
        string memory _stratergySymbol,
        address _vault,
        address _module,
        address _trader,
        address _oracle,
        address _investmentToken,
        uint256 _fee
    ) ERC20(_stratergyName, _stratergySymbol) {
        require(
            _trader != address(0) &&
                _investmentToken != address(0) &&
                _vault != address(0) &&
                _module != address(0) &&
                _oracle != address(0) &&
                _fee != 0,
            "Invalid Input"
        );
        isTradeEnabled = false;
        investmentToken = _investmentToken;
        vault = _vault;
        safe = IVelvetSafeModule(_module);
        oracle = IPriceOracle(_oracle);
        fee = _fee;
        index = address(this);
    }

    function deposit(address _token, uint256 _amount) external {
        require(_token == investmentToken, "Only USDC Supported");
        require(_amount > 0, "Investment Is InCorrect");
        require(isTradeEnabled == false, "Deposits Not Allowed");
        uint256 vaultBalanceInETH = _getVaultBalanceInETH();
        TransferHelper.safeTransferFrom(_token, msg.sender, vault, _amount);
        uint256 investAmountInUSD = oracle.getPriceTokenUSD18Decimals(
            _token,
            _amount
        );
        uint256 investAmountInETH = oracle.getUsdEthPrice(investAmountInUSD);
        uint256 _totalSupply = totalSupply();
        uint256 _tokenToMint = getTokenToMint(
            _totalSupply,
            investAmountInETH,
            vaultBalanceInETH
        );

        _mint(msg.sender, _tokenToMint);
        emit Deposit(msg.sender, _amount, _tokenToMint);
    }

    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Amount should be greater then 0");
        require(balanceOf(msg.sender) >= _amount, "Invalid Balance");
        require(
            isTradeEnabled == false,
            "Withdraw Not Allowed, You Can Request Automatic Withdrawal"
        );
        uint256 _totalSupply = totalSupply();

        //chargeFee and burn
        uint256 feeToBeCharged = (_amount.mul(fee)).div(PERCENTAGE);

        //amount after Fee
        uint256 amountAfterFee = _amount.sub(feeToBeCharged);
        uint256 userBalance = calculateUserShare(amountAfterFee, _totalSupply);
        _burn(msg.sender, amountAfterFee);

        //PullFromVault to User
        pullFromVault(investmentToken, userBalance, msg.sender);

        emit Withdraw(msg.sender, _amount, amountAfterFee, userBalance);
    }

    function requestWithdraw(uint256 _amount) external {
        require(isTradeEnabled, "Please Perform Normal Withdrawal");
        require(_amount > 0, "Amount should be greater then 0");
        require(balanceOf(msg.sender) >= _amount, "Invalid Balance");
        requestArray.push(WithdrawRequest(msg.sender, _amount));
        TransferHelper.safeTransfer(address(this), address(this), _amount);
    }

    function _getVaultBalanceInETH()
        internal
        view
        returns (uint256 balanceInETH)
    {
        if (totalSupply() > 0) {
            uint256 vaultBalance = IERC20(investmentToken).balanceOf(vault);
            uint256 balanceInUSD = oracle.getPriceTokenUSD18Decimals(
                investmentToken,
                vaultBalance
            );
            balanceInETH = oracle.getUsdEthPrice(balanceInUSD);
        } else {
            balanceInETH = 0;
        }
    }

    function getTokenToMint(
        uint256 _totalSupply,
        uint256 investedAmount,
        uint256 vaultBalance
    ) internal pure returns (uint256 tokenAmount) {
        if (_totalSupply > 0) {
            tokenAmount = investedAmount.mul(_totalSupply).div(vaultBalance);
        } else {
            tokenAmount = investedAmount;
        }
    }

    function calculateUserShare(
        uint256 _amount,
        uint256 _totalSupply
    ) internal view returns (uint256) {
        uint256 tokenBalance = IERC20(investmentToken).balanceOf(vault);
        return tokenBalance.mul(_amount).div(_totalSupply);
    }

    function startTrade() external onlyOwner {
        require(isTradeEnabled == false, "Trade Already OnGoing");

        //Trade Logic

        isTradeEnabled = true;
        emit TradeStarted(msg.sender);
    }

    function closeTrade() external onlyOwner {
        require(isTradeEnabled, "Trade Not Yet Started");
        lastTrade = block.timestamp;
        //Logic

        isTradeEnabled = false;
        emit TradeClosed(msg.sender);
    }

    function pullFromVault(address token, uint256 amount, address to) internal {
        _safeTokenTransfer(token, amount, to);
    }

    function _safeTokenTransfer(
        address token,
        uint256 amount,
        address to
    ) internal {
        bytes memory inputData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            to,
            amount
        );

        safe.executeWallet(token, inputData);
    }

    function checkUpKeep(
        bytes calldata checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        if (isTradeEnabled == false && lastUpKeep < lastTrade) {
            upkeepNeeded = true;
            performData = checkData;
        }
    }

    function performUpKeep(bytes calldata performData) external {
        for (uint256 i = 0; i < requestArray.length; i++) {
            uint256 _totalSupply = totalSupply();

            //chargeFee and burn
            uint256 _amount = requestArray[i].amount;
            uint256 feeToBeCharged = (_amount.mul(fee)).div(PERCENTAGE);

            //amount after Fee
            uint256 amountAfterFee = _amount.sub(feeToBeCharged);
            uint256 userBalance = calculateUserShare(
                amountAfterFee,
                _totalSupply
            );
            _burn(address(this), amountAfterFee);

            //PullFromVault to User
            pullFromVault(investmentToken, userBalance, requestArray[i].user);
        }
        TransferHelper.safeTransfer(
            address(this),
            vault,
            balanceOf(address(this))
        );
        delete requestArray;
        lastUpKeep = block.timestamp;
    }
}
