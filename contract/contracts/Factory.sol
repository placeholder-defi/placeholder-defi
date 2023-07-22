// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";
import {GnosisDeployer} from "contracts/library/GnosisDeployer.sol";
import {IVelvetSafeModule} from "./vault/IVelvetSafeModule.sol";
import "./VelvetShortTermFund.sol";

contract Factory is Ownable {
    address internal oracle;
    address public gnosisSingleton;
    address public gnosisFallbackLibrary;
    address public gnosisMultisendLibrary;
    address public gnosisSafeProxyFactory;
    address internal baseVelvetGnosisSafeModuleAddress;

    struct FundInfo{
        address shortTermFund;
    }

    FundInfo[] public FundInfolList;

    event VaultCreated(address vault,address indexed trade);

    constructor(
        address _oracle,
        address _gnosisSingleton,
        address _gnosisFallbackLibrary,
        address _gnosisMultisendLibrary,
        address _gnosisSafeProxyFactory,
        address _baseVelvetGnosisSafeModuleAddress
    ) {
        oracle = _oracle;
        gnosisSingleton = _gnosisSingleton;
        gnosisFallbackLibrary = _gnosisFallbackLibrary;
        gnosisMultisendLibrary = _gnosisMultisendLibrary;
        gnosisSafeProxyFactory = _gnosisSafeProxyFactory;
        baseVelvetGnosisSafeModuleAddress = _baseVelvetGnosisSafeModuleAddress;
    }

    function createCustodialVault(
        string memory _stratergyName,
        string memory _stratergySymbol,
        address _investmentToken,
        uint256 _fee,
        address[] memory _owners,
        uint256 _threshold
    ) external returns (address) {
        require(_owners.length > 0, "Owners length should be grater then zero");
        require(
            _threshold <= _owners.length && _threshold > 0,
            "Invalid Threshold Length"
        );
        return
            _createVault(
                _stratergyName,
                _stratergySymbol,
                _investmentToken,
                _fee,
                true,
                _owners,
                _threshold
            );
    }

    function createNonCustodialVault(
        string memory _stratergyName,
        string memory _stratergySymbol,
        address _investmentToken,
        uint256 _fee
    ) external returns (address) {
        address[] memory _owner = new address[](1);
        _owner[0] = address(0x0000000000000000000000000000000000000000);
        return
            _createVault(
                _stratergyName,
                _stratergySymbol,
                _investmentToken,
                _fee,
                false,
                _owner,
                1
            );
    }

    function _createVault(
        string memory _stratergyName,
        string memory _stratergySymbol,
        address _investmentToken,
        uint256 _fee,
        bool _custodial,
        address[] memory _owner,
        uint256 _threshold
    ) internal returns (address) {
        address vaultAddress;
        address module;
        if (!_custodial) {
            _owner[0] = msg.sender;
            _threshold = 1;
        }
        (vaultAddress, module) = GnosisDeployer.deployGnosisSafeAndModule(
            gnosisSingleton,
            gnosisSafeProxyFactory,
            gnosisMultisendLibrary,
            gnosisFallbackLibrary,
            baseVelvetGnosisSafeModuleAddress,
            _owner,
            _threshold
        );
        VelvetShortTermFund velvetFundContract = new VelvetShortTermFund(
            _stratergyName,
            _stratergySymbol,
            vaultAddress,
            module,
            msg.sender,
            oracle,
            _investmentToken,
            _fee
        );
        IVelvetSafeModule(address(module)).setUp(
            abi.encode(
                vaultAddress,
                address(velvetFundContract),
                address(gnosisMultisendLibrary)
            )
        );

        FundInfolList.push(FundInfo(address(velvetFundContract)));
        emit VaultCreated(address(velvetFundContract),msg.sender);
        return address(velvetFundContract);
    }

    function getFundList(uint256 fundId) external view virtual returns (address) {
    return address(FundInfolList[fundId].shortTermFund);
  }
}
