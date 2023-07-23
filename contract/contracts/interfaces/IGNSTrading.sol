// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGNSTrading {
    // Events
    event Done(bool done);
    event Paused(bool paused);
    event NumberUpdated(string name, uint value);
    event MarketOrderInitiated(uint indexed orderId, address indexed trader, uint indexed pairIndex, bool open);
    event OpenLimitPlaced(address indexed trader, uint indexed pairIndex, uint index);
    event OpenLimitUpdated(address indexed trader, uint indexed pairIndex, uint index, uint newPrice, uint newTp, uint newSl);
    event OpenLimitCanceled(address indexed trader, uint indexed pairIndex, uint index);
    event TpUpdated(address indexed trader, uint indexed pairIndex, uint index, uint newTp);
    event SlUpdated(address indexed trader, uint indexed pairIndex, uint index, uint newSl);
    event SlUpdateInitiated(uint indexed orderId, address indexed trader, uint indexed pairIndex, uint index, uint newSl);
    event NftOrderInitiated(uint orderId, address indexed nftHolder, address indexed trader, uint indexed pairIndex);
    event NftOrderSameBlock(address indexed nftHolder, address indexed trader, uint indexed pairIndex);
    event ChainlinkCallbackTimeout(uint indexed orderId, StorageInterfaceV5.PendingMarketOrder order);
    event CouldNotCloseTrade(address indexed trader, uint indexed pairIndex, uint index);

    // Modifiers
    modifier onlyGov();
    modifier notContract();
    modifier notDone();

    // Manage params
    function setMaxPosDai(uint value) external;

    function setMarketOrdersTimeout(uint value) external;

    // Manage state
    function pause() external;

    function done() external;

    // Open new trade (MARKET/LIMIT)
    function openTrade(
        StorageInterfaceV5.Trade memory t,
        NftRewardsInterfaceV6_3_1.OpenLimitOrderType orderType,
        uint spreadReductionId,
        uint slippageP,
        address referrer
    ) external;

    // Close trade (MARKET)
    function closeTradeMarket(uint pairIndex, uint index) external;

    // Manage limit order (OPEN)
    function updateOpenLimitOrder(
        uint pairIndex,
        uint index,
        uint price,
        uint tp,
        uint sl
    ) external;

    function cancelOpenLimitOrder(uint pairIndex, uint index) external;

    // Manage limit order (TP/SL)
    function updateTp(uint pairIndex, uint index, uint newTp) external;

    function updateSl(uint pairIndex, uint index, uint newSl) external;

    // Execute limit order
    function executeNftOrder(
        StorageInterfaceV5.LimitOrder orderType,
        address trader,
        uint pairIndex,
        uint index,
        uint nftId,
        uint nftType
    ) external;

    // Market timeout
    function openTradeMarketTimeout(uint _order) external;

    function closeTradeMarketTimeout(uint _order) external;
}
