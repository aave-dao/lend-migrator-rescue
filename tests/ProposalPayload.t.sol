// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';
import {GovV3Helpers} from 'aave-helpers/GovV3Helpers.sol';

import {IInitializableAdminUpgradeabilityProxy} from 'src/interfaces/IInitializableAdminUpgradeabilityProxy.sol';
import {LendToAaveMigrator} from 'src/LendToAaveMigrator.sol';
import {ProposalPayload} from 'src/proposals/ProposalPayload.sol';

contract ProposalPayloadTest is Test {
  IERC20 public constant AAVE = IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING);
  IERC20 public constant LEND = IERC20(0x80fB784B7eD66730e8b1DBd9820aFD29931aab03);
  uint256 public constant LEND_AAVE_RATIO = 100;
  address public constant ECOSYSTEM_RESERVE = MiscEthereum.ECOSYSTEM_RESERVE;

  address payable public migratorProxyAddress = payable(0x317625234562B1526Ea2FaC4030Ea499C5291de4);

  LendToAaveMigrator public migratorImpl;
  IInitializableAdminUpgradeabilityProxy public migratorProxy;
  LendToAaveMigrator public migrator;
  ProposalPayload public payload;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'));

    migratorImpl = new LendToAaveMigrator(AAVE, LEND, LEND_AAVE_RATIO, ECOSYSTEM_RESERVE);
    migratorProxy = IInitializableAdminUpgradeabilityProxy(migratorProxyAddress);
    migrator = LendToAaveMigrator(migratorProxyAddress);

    payload = new ProposalPayload(address(migratorImpl));
  }

  function test_execute() public {
    assertEq(migratorProxy.REVISION(), 2);

    uint256 preMigratorAaveBalance = AAVE.balanceOf(address(migrator));
    uint256 preEcosystemReserveAaveBalance = AAVE.balanceOf(ECOSYSTEM_RESERVE);

    vm.expectEmit(address(migrator));
    emit LendToAaveMigrator.AaveTokensRescued(
      address(migrator),
      ECOSYSTEM_RESERVE,
      preMigratorAaveBalance
    );
    GovV3Helpers.executePayload(vm, address(payload));

    assertEq(migratorProxy.REVISION(), 3);
    assertEq(AAVE.balanceOf(address(migrator)), 0);
    assertEq(
      AAVE.balanceOf(ECOSYSTEM_RESERVE),
      preEcosystemReserveAaveBalance + preMigratorAaveBalance
    );
    assertTrue(migrator.migrationStarted());
    assertTrue(migrator.migrationEnded());

    vm.expectRevert(LendToAaveMigrator.MigrationClosed.selector);
    migrator.migrateFromLEND(1);
  }

  function test_execute_immutables() public view {
    assertEq(payload.LEND_TO_AAVE_MIGRATOR_IMPL(), address(migratorImpl));
    assertEq(payload.LEND_TO_AAVE_MIGRATOR_PROXY(), migratorProxyAddress);
  }
}
