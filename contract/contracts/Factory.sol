// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";
import {GnosisDeployer} from "./library/GnosisDeployer.sol";
import {ISafeModule} from "./vault/ISafeModule.sol";
import "./ShortTermFund.sol";
import "./IShortTermFund.sol";

contract Factory is Ownable {
    address internal oracle;
    address internal gnosisSingleton;
    address internal gnosisFallbackLibrary;
    address internal gnosisMultisendLibrary;
    address internal gnosisSafeProxyFactory;
    address internal baseVelvetGnosisSafeModuleAddress;
    address internal router;
    address internal positionRouter;

    struct FundInfo {
        address shortTermFund;
        string stratergyName;
        string stratergysymbol;
        address owner;
    }

    FundInfo[] public FundInfolList;

    event VaultCreated(address vault, address indexed trade);

    constructor(
        address _oracle,
        address _gnosisSingleton,
        address _gnosisFallbackLibrary,
        address _gnosisMultisendLibrary,
        address _gnosisSafeProxyFactory,
        address _baseVelvetGnosisSafeModuleAddress,
        address _router,
        address _positionRouter
    ) {
        oracle = _oracle;
        gnosisSingleton = _gnosisSingleton;
        gnosisFallbackLibrary = _gnosisFallbackLibrary;
        gnosisMultisendLibrary = _gnosisMultisendLibrary;
        gnosisSafeProxyFactory = _gnosisSafeProxyFactory;
        baseVelvetGnosisSafeModuleAddress = _baseVelvetGnosisSafeModuleAddress;
        router = _router;
        positionRouter = _positionRouter;
        
    }

    function createCustodialVault(
        string memory _stratergyName,
        string memory _stratergySymbol,
        address _investmentToken,
        uint256 _fee
    ) external {
        address[] memory _owner = new address[](1);
        _owner[0] = msg.sender;
        _createVault(
            _stratergyName,
            _stratergySymbol,
            _investmentToken,
            _fee,
            _owner,
            1
        );
    }

    function createNonCustodialVault(
        string memory _stratergyName,
        string memory _stratergySymbol,
        address _investmentToken,
        uint256 _fee
    ) external {
        address[] memory _owner = new address[](1);
        _owner[0] = msg.sender;
        _createVault(
            _stratergyName,
            _stratergySymbol,
            _investmentToken,
            _fee,
            _owner,
            1
        );
    }

    function _createVault(
        string memory _stratergyName,
        string memory _stratergySymbol,
        address _investmentToken,
        uint256 _fee,
        address[] memory _owner,
        uint256 _threshold
    ) internal {
        address vaultAddress;
        address module;
        (vaultAddress, module) = GnosisDeployer.deployGnosisSafeAndModule(
            gnosisSingleton,
            gnosisSafeProxyFactory,
            gnosisMultisendLibrary,
            gnosisFallbackLibrary,
            baseVelvetGnosisSafeModuleAddress,
            _owner,
            _threshold
        );
        ShortTermFund shortTermFund = new ShortTermFund(_stratergyName,
                _stratergySymbol,
                vaultAddress,
                module,
                msg.sender,
                oracle,
                _investmentToken,
                router,
                positionRouter,
                _fee); 
        ISafeModule(address(module)).setUp(
            abi.encode(
                vaultAddress,
                address(shortTermFund),
                address(gnosisMultisendLibrary)
            )
        );

        FundInfolList.push(
            FundInfo(
                address(shortTermFund),
                _stratergyName,
                _stratergySymbol,
                msg.sender
            )
        );
        emit VaultCreated(address(shortTermFund), msg.sender);
    }

    function getFundList(
        uint256 fundId
    ) external view virtual returns (address) {
        return address(FundInfolList[fundId].shortTermFund);
    }
}
