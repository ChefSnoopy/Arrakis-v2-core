// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IArrakisV2Factory} from "./interfaces/IArrakisV2Factory.sol";
import {IArrakisV2} from "./interfaces/IArrakisV2.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract StratRegistry is Ownable {
    bytes32 public constant STRING_EMPTY = keccak256(abi.encodePacked(""));

    // #region events.

    event AddStratType(string indexed stratType);
    event RemoveStratType(string indexed stratType);

    // #region events related to Vault.
    event SubscribeRebalance(address indexed vaultV2, string stratType);
    event UnSubscribe(address indexed vaultV2);
    event ChangeSubscription(
        address indexed vaultV2,
        string oldStratType,
        string newStratType
    );
    // #endregion events related to Vault.

    // #endregion events.

    // solhint-disable ordering
    IArrakisV2Factory private immutable _factory;

    mapping(string => bool) public stratExist;
    mapping(address => string) public vaultByStrat;

    constructor(IArrakisV2Factory factory_) Ownable() {
        _factory = factory_;
    }

    // #region modifiers

    modifier onlyVaultV2(address vaultV2_) {
        address[] memory vaults = _factory.getVaultsByDeployer(
            address(IArrakisV2(vaultV2_).manager())
        );

        bool contain = false;

        for (uint256 i = 0; i < vaults.length; i++) {
            contain = vaults[i] == vaultV2_;

            if (contain) break;
        }

        require(contain, "no vaultV2");
        _;
    }

    modifier onlyVaultManager(address vaultV2_) {
        require(
            address(IArrakisV2(vaultV2_).manager()) == msg.sender,
            "not vault manager"
        );
        _;
    }

    // #endregion modifiers

    // #region admin

    function addStratType(string calldata stratType_) external onlyOwner {
        require(!stratExist[stratType_], "strat");

        stratExist[stratType_] = true;
        emit AddStratType(stratType_);
    }

    function removeStratType(string calldata stratType_) external onlyOwner {
        require(stratExist[stratType_], "no strat");

        stratExist[stratType_] = false;
        emit RemoveStratType(stratType_);
    }

    // #endregion admin

    function subscribe(address vaultV2_, string calldata stratType_)
        external
        onlyVaultManager(vaultV2_)
        onlyVaultV2(vaultV2_)
    {
        require(
            keccak256(abi.encodePacked(vaultByStrat[vaultV2_])) == STRING_EMPTY,
            "subscribe"
        );
        require(stratExist[stratType_], "no strat");

        vaultByStrat[vaultV2_] = stratType_;
        emit SubscribeRebalance(vaultV2_, stratType_);
    }

    function unsubscribe(address vaultV2_)
        external
        onlyVaultManager(vaultV2_)
        onlyVaultV2(vaultV2_)
    {
        require(
            keccak256(abi.encodePacked(vaultByStrat[vaultV2_])) != STRING_EMPTY,
            "no subscribe"
        );

        vaultByStrat[vaultV2_] = "";
        emit UnSubscribe(vaultV2_);
    }

    function changeSubscription(address vaultV2_, string calldata stratType_)
        external
        onlyVaultManager(vaultV2_)
        onlyVaultV2(vaultV2_)
    {
        require(stratExist[stratType_], "no strat");

        string memory oldStrat = vaultByStrat[vaultV2_];

        vaultByStrat[vaultV2_] = stratType_;
        emit ChangeSubscription(vaultV2_, oldStrat, stratType_);
    }
}