// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';

import {IInitializableAdminUpgradeabilityProxy} from 'src/interfaces/IInitializableAdminUpgradeabilityProxy.sol';
import {LendToAaveMigrator} from 'src/LendToAaveMigrator.sol';

contract LendToAaveMigratorTest is Test {
  // Legacy immutables
  IERC20 public constant AAVE = IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING);
  IERC20 public constant LEND = IERC20(0x80fB784B7eD66730e8b1DBd9820aFD29931aab03);
  uint256 public constant LEND_AAVE_RATIO = 100;
  address public constant ECOSYSTEM_RESERVE = MiscEthereum.ECOSYSTEM_RESERVE;

  address public immutable MIGRATOR_PROXY_ADMIN = MiscEthereum.PROXY_ADMIN;
  address payable public migratorProxyAddress = payable(0x317625234562B1526Ea2FaC4030Ea499C5291de4);

  LendToAaveMigrator public migratorImpl;
  IInitializableAdminUpgradeabilityProxy public migratorProxy;
  LendToAaveMigrator public migrator;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'));

    migratorImpl = new LendToAaveMigrator(AAVE, LEND, LEND_AAVE_RATIO, ECOSYSTEM_RESERVE);
    migratorProxy = IInitializableAdminUpgradeabilityProxy(migratorProxyAddress);
    migrator = LendToAaveMigrator(migratorProxyAddress);
  }

  function test_contructor() public view {
    assertEq(address(migratorImpl.AAVE()), address(AAVE));
    assertEq(address(migratorImpl.LEND()), address(LEND));
    assertEq(migratorImpl.LEND_AAVE_RATIO(), LEND_AAVE_RATIO);
    assertEq(migratorImpl.ECOSYSTEM_RESERVE(), ECOSYSTEM_RESERVE);

    assertEq(migratorImpl.REVISION(), 3);

    assertEq(address(migrator.AAVE()), address(AAVE));
    assertEq(address(migrator.LEND()), address(LEND));
    assertEq(migrator.LEND_AAVE_RATIO(), LEND_AAVE_RATIO);

    assertEq(migrator.REVISION(), 2);
  }

  function test_initialize() public {
    assertEq(migrator.REVISION(), 2);

    uint256 currentAaveBalanceMigrator = AAVE.balanceOf(address(migrator));
    uint256 currentAaveBalanceRecipient = AAVE.balanceOf(ECOSYSTEM_RESERVE);

    vm.expectEmit(address(migrator));
    emit LendToAaveMigrator.AaveTokensRescued(
      address(migrator),
      ECOSYSTEM_RESERVE,
      currentAaveBalanceMigrator
    );
    vm.prank(MIGRATOR_PROXY_ADMIN);
    migratorProxy.upgradeToAndCall(address(migratorImpl), abi.encodeWithSignature('initialize()'));

    assertEq(migratorProxy.REVISION(), 3);

    assertEq(AAVE.balanceOf(address(migrator)), 0);
    assertEq(
      AAVE.balanceOf(ECOSYSTEM_RESERVE),
      currentAaveBalanceRecipient + currentAaveBalanceMigrator
    );
  }

  function test_migrationStarted() public {
    assertTrue(migrator.migrationStarted());

    vm.prank(MIGRATOR_PROXY_ADMIN);
    migratorProxy.upgradeToAndCall(address(migratorImpl), abi.encodeWithSignature('initialize()'));

    assertTrue(migrator.migrationStarted());
  }

  function test_migrationEnded() public {
    vm.prank(MIGRATOR_PROXY_ADMIN);
    migratorProxy.upgradeToAndCall(address(migratorImpl), abi.encodeWithSignature('initialize()'));

    assertTrue(migrator.migrationEnded());
  }

  function test_migrateFromLEND_revertsWithMigrationClosed(uint256 amount) public {
    vm.prank(MIGRATOR_PROXY_ADMIN);
    migratorProxy.upgradeToAndCall(address(migratorImpl), abi.encodeWithSignature('initialize()'));

    vm.expectRevert(LendToAaveMigrator.MigrationClosed.selector);
    migrator.migrateFromLEND(amount);
  }
}
