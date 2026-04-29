// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {IProposalGenericExecutor} from 'aave-helpers/interfaces/IProposalGenericExecutor.sol';
import {IProxyAdminOzV4} from 'solidity-utils/contracts/transparent-proxy/interfaces/IProxyAdminOzV4.sol';

/**
 * @title ProposalPayload
 * @author Aave
 * @notice Aave Governance V3 payload that upgrades the LendToAaveMigrator proxy
 * to a new implementation and atomically calls `initialize()` on it, sweeping
 * the migrator's AAVE balance to the Aave Collector and permanently closing
 * the LEND -> AAVE migration.
 */
contract ProposalPayload is IProposalGenericExecutor {
  /// @notice Address of the LendToAaveMigrator transparent proxy on mainnet
  address public constant LEND_TO_AAVE_MIGRATOR_PROXY = 0x317625234562B1526Ea2FaC4030Ea499C5291de4;

  /// @notice Address of the new LendToAaveMigrator implementation to upgrade to
  address public immutable LEND_TO_AAVE_MIGRATOR_IMPL;

  /**
   * @param lendToAaveMigratorImpl the address of the new LendToAaveMigrator implementation
   */
  constructor(address lendToAaveMigratorImpl) {
    LEND_TO_AAVE_MIGRATOR_IMPL = lendToAaveMigratorImpl;
  }

  /// @inheritdoc IProposalGenericExecutor
  function execute() external {
    IProxyAdminOzV4(MiscEthereum.PROXY_ADMIN).upgradeAndCall(
      LEND_TO_AAVE_MIGRATOR_PROXY,
      LEND_TO_AAVE_MIGRATOR_IMPL,
      abi.encodeWithSignature('initialize()')
    );
  }
}
