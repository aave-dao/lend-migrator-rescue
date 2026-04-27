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

  address public immutable MIGRATOR_PROXY_ADMIN = MiscEthereum.PROXY_ADMIN;
  address payable public migratorProxyAddress = payable(0x317625234562B1526Ea2FaC4030Ea499C5291de4);

  address public recipient;

  LendToAaveMigrator public migratorImpl;
  IInitializableAdminUpgradeabilityProxy public migratorProxy;
  LendToAaveMigrator public migrator;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl('mainnet'));

    recipient = makeAddr('recipient');

    migratorImpl = new LendToAaveMigrator(AAVE, LEND, LEND_AAVE_RATIO);
    migratorProxy = IInitializableAdminUpgradeabilityProxy(migratorProxyAddress);
    migrator = LendToAaveMigrator(migratorProxyAddress);
  }

  function test_contructor() public view {
    assertEq(address(migratorImpl.AAVE()), address(AAVE));
    assertEq(address(migratorImpl.LEND()), address(LEND));
    assertEq(migratorImpl.LEND_AAVE_RATIO(), LEND_AAVE_RATIO);

    assertEq(migratorImpl.REVISION(), 3);
  }

  function test_initialize() public {
    assertEq(migrator.REVISION(), 2);

    uint256 currentAaveBalanceMigrator = AAVE.balanceOf(address(migrator));
    uint256 currentAaveBalanceRecipient = AAVE.balanceOf(recipient);

    vm.expectEmit(address(migrator));
    emit LendToAaveMigrator.AaveTokensRescued(
      address(migrator),
      recipient,
      currentAaveBalanceMigrator
    );
    vm.prank(MIGRATOR_PROXY_ADMIN);
    migratorProxy.upgradeToAndCall(
      address(migratorImpl),
      abi.encodeWithSignature('initialize(address)', recipient)
    );

    assertEq(migratorProxy.REVISION(), 3);

    assertEq(AAVE.balanceOf(address(migrator)), 0);
    assertEq(AAVE.balanceOf(recipient), currentAaveBalanceRecipient + currentAaveBalanceMigrator);
  }

  function test_initialize_revertsEmpty() public {
    // we expect an empty revert as the emitted InvalidRecipient does not bubble up
    vm.expectRevert();
    vm.prank(MIGRATOR_PROXY_ADMIN);
    migratorProxy.upgradeToAndCall(
      address(migratorImpl),
      abi.encodeWithSignature('initialize(address)', address(0))
    );
  }

  function test_migrationStarted() public {
    assertTrue(migrator.migrationStarted());

    vm.prank(MIGRATOR_PROXY_ADMIN);
    migratorProxy.upgradeToAndCall(
      address(migratorImpl),
      abi.encodeWithSignature('initialize(address)', recipient)
    );

    assertFalse(migrator.migrationStarted());
  }

  function test_migrateFromLEND_revertsWithMigrationClosed(uint256 amount) public {
    vm.prank(MIGRATOR_PROXY_ADMIN);
    migratorProxy.upgradeToAndCall(
      address(migratorImpl),
      abi.encodeWithSignature('initialize(address)', recipient)
    );

    vm.expectRevert(LendToAaveMigrator.MigrationClosed.selector);
    migrator.migrateFromLEND(amount);
  }
}
