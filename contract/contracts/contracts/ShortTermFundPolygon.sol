// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IPriceOracle.sol";
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import {ISafeModule} from "./vault/ISafeModule.sol";
import "./interfaces/IPositionRouter.sol";
import "./interfaces/IRouter.sol";
import "./IOneInchHandler.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract ShortTermFundPolygon is Initializable, ERC20Upgradeable {
    using SafeMath for uint256;

    bool private isTradeEnabled;
    address private vault;
    address private investmentToken;
    address private index;
    uint256 private fee;
    uint256 private lastTrade;
    uint256 private lastUpKeep;
    IPriceOracle private oracle;
    ISafeModule private safe;
    IPositionRouter private positionRouter;
    IRouter private router;

    address public trader;

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
    ) external initializer {
        __ERC20_init(_stratergyName, _stratergySymbol);
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
        safe = ISafeModule(_module);
        oracle = IPriceOracle(_oracle);
        router = IRouter(_router);
        positionRouter = IPositionRouter(_positionRouter);
        fee = _fee;
        trader = _trader;
        index = address(this);
    }

    modifier onlyTrader() {
        require(msg.sender == trader, "Caller Not Trader");
        _;
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
        TransferHelper.safeTransferFrom(
            address(this),
            msg.sender,
            address(this),
            _amount
        );
    }

    function _getVaultBalanceInETH()
        internal
        view
        returns (uint256 balanceInETH)
    {
        if (totalSupply() > 0) {
            uint256 vaultBalance = IERC20Upgradeable(investmentToken).balanceOf(
                vault
            );
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
        uint256 tokenBalance = IERC20Upgradeable(investmentToken).balanceOf(
            vault
        );
        return tokenBalance.mul(_amount).div(_totalSupply);
    }

    function startTrade(
        address _inputToken,
        address[] memory _path,
        address _indexToken,
        uint _amountIn,
        bool _isLong,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable onlyTrader {
        require(isTradeEnabled == false, "Trade Already OnGoing");

        //Trade Logic
        pullFromVault(_inputToken, _amountIn, address(this));
        router.approvePlugin(address(positionRouter));
        TransferHelper.safeApprove(_inputToken, address(router), _amountIn);
        uint executionFee = positionRouter.minExecutionFee();

        uint priceETH = oracle
            .getNormalizedRate(_indexToken, _inputToken)
            .mul(1000000000000000000)
            .mul(10 ** 12);
        uint sizeDelta = oracle
            .getNormalizedRate(
                _inputToken,
                address(0x0000000000000000000000000000000000000348)
            )
            .mul(_amountIn)
            .mul(10 ** 12);
        // positionRouter.createIncreasePosition{value: msg.value}(_path, _indexToken, _amountIn, 0, _amountIn.mul(10**30), _isLong, _getTokenPriceETHUSD(1000000000000000000).mul(10**30), positionRouter.minExecutionFee(), _referralCode, _callbackTarget);
        positionRouter.createIncreasePosition{value: executionFee}(
            _path,
            _indexToken,
            _amountIn,
            0,
            sizeDelta,
            _isLong,
            priceETH,
            executionFee,
            _referralCode,
            _callbackTarget
        );

        isTradeEnabled = true;
        emit TradeStarted(msg.sender);
    }

    function closeTrade() external onlyTrader {
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
            IERC20Upgradeable.transfer.selector,
            to,
            amount
        );

        safe.executeWallet(token, inputData);
    }

    function swapUsingOnceInchHandler(
        address sellToken,
        address buyToken,
        address _to,
        address _oneInchHandler,
        uint256 _amount,
        bytes memory _swapData
    ) external {
        TransferHelper.safeTransfer(
            sellToken,
            _oneInchHandler,
            _amount
        );
        IOneInchHandler(_oneInchHandler).swap(
            sellToken,
            buyToken,
            _amount,
            _swapData,
            _to
        );
    }

    function checkUpKeep(
        bytes calldata checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        if (isTradeEnabled == false && lastUpKeep < lastTrade) {
            upkeepNeeded = true;
            performData = checkData;
        }
    }

    function performUpKeep(bytes calldata /* performData */) external {
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
