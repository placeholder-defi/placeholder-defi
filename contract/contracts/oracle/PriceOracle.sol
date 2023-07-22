// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";

contract PriceOracle is Ownable {
    using SafeMath for uint256;

    struct AggregatorInfo {
        mapping(address => AggregatorV2V3Interface) aggregatorInterfaces;
    }

    mapping(address => AggregatorInfo) internal aggregatorAddresses;

    function getAggregatorInterface() public {}


	uint8 private constant SCALE_DECIMALS = 18;
	// seconds since the last price feed update until we deem the data to be stale
	// uint32 private constant STALE_PRICE_DELAY = 3600;

    /**
     * @notice Retrieve the aggregator of an base / quote pair in the current phase
     * @param base base asset address
     * @param quote quote asset address
     * @return aggregator
     */
    function _getFeed(address base, address quote)
        internal
        view
        returns (AggregatorV2V3Interface aggregator)
    {
        aggregator = aggregatorAddresses[base].aggregatorInterfaces[quote];
    }

    /**
     * @notice Add a new aggregator of an base / quote pair
     * @param base base asset address
     * @param quote quote asset address
     * @param aggregator aggregator
     */
    function _addFeed(
        address base,
        address quote,
        AggregatorV2V3Interface aggregator
    ) public onlyOwner {
        require(
            aggregatorAddresses[base].aggregatorInterfaces[quote] ==
                AggregatorInterface(address(0)),
            "Aggregator already exists"
        );
        aggregatorAddresses[base].aggregatorInterfaces[quote] = aggregator;
    }

    /**
     * @notice Updatee an existing feed
     * @param base base asset address
     * @param quote quote asset address
     * @param aggregator aggregator
     */
    function _updateFeed(
        address base,
        address quote,
        AggregatorV2V3Interface aggregator
    ) public onlyOwner {
        aggregatorAddresses[base].aggregatorInterfaces[quote] = aggregator;
    }

    /**
     * @notice Returns the decimals of a token pair price feed
     * @param base base asset address
     * @param quote quote asset address
     * @return Decimals of the token pair
     */
    function decimals(address base, address quote) public view returns (uint8) {
        AggregatorV2V3Interface aggregator = _getFeed(base, quote);
        require(address(aggregator) != address(0), "Feed not found");
        return aggregator.decimals();
    }

    /**
     * @notice Returns the latest price
     * @param base base asset address
     * @param quote quote asset address
     * @return The latest token price of the pair
     */
    function latestRoundData(address base, address quote)
        internal
        view
        returns (int256)
    {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = aggregatorAddresses[base]
                .aggregatorInterfaces[quote]
                .latestRoundData();
        return price;
    }

    /**
     * @notice Returns the latest ETH price for a specific token amount
     * @param amountIn The amount of base tokens to be converted to ETH
     * @return amountOut The latest ETH token price of the base token
     */
    function getUsdEthPrice(uint256 amountIn)
        public
        view
        returns (uint256 amountOut)
    {
        uint256 price = uint256(
            latestRoundData(Denominations.ETH, Denominations.USD)
        );

        uint256 decimal = decimals(Denominations.ETH, Denominations.USD);
        amountOut = amountIn.mul(10**decimal).div(price);
    }

    /**
     * @notice Returns the latest USD price for a specific token amount
     * @param amountIn The amount of base tokens to be converted to ETH
     * @return amountOut The latest USD token price of the base token
     */
    function getEthUsdPrice(uint256 amountIn)
        public
        view
        returns (uint256 amountOut)
    {
        uint256 price = uint256(
            latestRoundData(Denominations.ETH, Denominations.USD)
        );

        uint256 decimal = decimals(Denominations.ETH, Denominations.USD);
        amountOut = amountIn.mul(price).div(10**decimal);
    }

    /**
     * @notice Returns the latest price
     * @param base base asset address
     * @param quote quote asset address
     * @return The latest token price of the pair
     */
    function getPrice(address base, address quote)
        public
        view
        returns (int256)
    {
        int256 price = latestRoundData(base, quote);
        return price;
    }

    /**
     * @notice Returns the latest price for a specific amount
     * @param token token asset address
     * @return amountOut The latest token price of the pair
     */
    function getPriceForAmount(
        address token,
        uint256 amount,
        bool ethPath
    ) public view returns (uint256 amountOut) {
        IERC20Metadata t = IERC20Metadata(token);
        uint8 decimal = t.decimals();
        uint256 diff = uint256(18).sub(decimal);

        if (ethPath) {
            uint256 price = getPriceTokenUSD(token, amount);
            amountOut = getUsdEthPrice(price).div(10**diff);
        } else {
            uint256 price = uint256(
                latestRoundData(Denominations.ETH, Denominations.USD)
            );
            uint256 decimal = decimals(Denominations.ETH, Denominations.USD);
            amountOut = getPriceUSDToken(
                token,
                price.mul(amount).div(10**decimal)
            ).div(10**diff);
        }
    }

    /**
     * @notice Returns the latest USD price for a specific token and amount
     * @param _base base asset address
     * @param amountIn The amount of base tokens to be converted to USD
     * @return amountOut The latest USD token price of the base token
     */
    function getPriceTokenUSD(address _base, uint256 amountIn)
        public
        view
        returns (uint256 amountOut)
    {
        uint256 output = uint256(getPrice(_base, Denominations.USD));
        uint256 decimal = decimals(_base, Denominations.USD);
        amountOut = output.mul(amountIn).div(10**decimal);
    }

    /**
     * @notice Returns the latest USD price for a specific token and amount
     * @param _base base asset address
     * @param amountIn The amount of base tokens to be converted to USD
     * @return amountOut The latest USD token price of the base token
     */
    function getPriceTokenUSD18Decimals(address _base, uint256 amountIn)
        public
        view
        returns (uint256 amountOut)
    {
        uint256 output = uint256(getPrice(_base, Denominations.USD));
        uint256 decimalChainlink = decimals(_base, Denominations.USD);
        IERC20Metadata token = IERC20Metadata(_base);
        uint8 decimal = token.decimals();

        uint256 diff = uint256(18).sub(decimal);

        amountOut = output.mul(amountIn).div(10**decimalChainlink).mul(
            10**diff
        );
    }

    /**
     * @notice Returns the latest token price for a specific USD amount
     * @param _base base asset address
     * @param amountIn The amount of base tokens to be converted to USD
     * @return amountOut The latest USD token price of the base token
     */
    function getPriceUSDToken(address _base, uint256 amountIn)
        public
        view
        returns (uint256 amountOut)
    {
        uint256 output = uint256(getPrice(_base, Denominations.USD));
        uint256 decimal = decimals(_base, Denominations.USD);
        amountOut = amountIn.mul(10**decimal).div(output);
    }

function getPriceForTokenAmount(
    address tokenIn,
    address tokenOut,
    uint256 amount
  ) public view returns (uint256 amountOut) {
    // getPriceTokenUSD18Decimals returns usd amount in 18 decimals
    uint256 price = getPriceTokenUSD18Decimals(tokenIn, amount);
    // getPriceUSDToken returns the amount in decimals of token (out)
    amountOut = getPriceUSDToken(tokenOut, price);
  }

  function getNormalizedRate(address underlying, address strike) external view returns (uint256) {
		// address feedAddress = priceFeeds[underlying][strike];
        address feedAddress = address(_getFeed(underlying, strike));
		// require(feedAddress != address(0), "Price feed does not exist");
		AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
		uint8 feedDecimals = feed.decimals();
		(uint80 roundId, int256 rate, , uint256 timestamp, uint80 answeredInRound) = feed
			.latestRoundData();
		require(rate > 0, "ChainLinkPricer: price is lower than 0");
		require(timestamp != 0, "ROUND_NOT_COMPLETE");
		// require(block.timestamp <= timestamp + STALE_PRICE_DELAY, "STALE_PRICE");
		require(answeredInRound >= roundId, "STALE_PRICE_ROUND");
		uint8 difference;
		if (SCALE_DECIMALS > feedDecimals) {
			difference = SCALE_DECIMALS - feedDecimals;
			return uint256(rate) * (10**difference);
		}
		difference = feedDecimals - SCALE_DECIMALS;
		return uint256(rate) / (10**difference);
	}
}
