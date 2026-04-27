```diff --git a/./etherscan/LendToAaveMigrator/src/contracts/LendToAaveMigrator.sol b/./src/LendToAaveMigrator.sol
index 59db969..067a4e7 100644
--- a/./etherscan/LendToAaveMigrator/src/contracts/LendToAaveMigrator.sol
+++ b/./src/LendToAaveMigrator.sol
@@ -1,8 +1,9 @@
 // SPDX-License-Identifier: agpl-3.0
 pragma solidity ^0.8.0;
 
-import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
-import {VersionedInitializable} from './dependencies/upgradeability/VersionedInitializable.sol';
+import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
+import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
+import {VersionedInitializable} from 'src/dependencies/VersionedInitializable.sol';
 
 /**
  * @title LendToAaveMigrator
@@ -10,10 +11,12 @@ import {VersionedInitializable} from './dependencies/upgradeability/VersionedIni
  * @author Aave
  */
 contract LendToAaveMigrator is VersionedInitializable {
+  using SafeERC20 for IERC20;
+
   IERC20 public immutable AAVE;
   IERC20 public immutable LEND;
   uint256 public immutable LEND_AAVE_RATIO;
-  uint256 public constant REVISION = 2;
+  uint256 public constant REVISION = 3;
 
   uint256 public _totalLendMigrated;
 
@@ -32,12 +35,22 @@ contract LendToAaveMigrator is VersionedInitializable {
    */
   event AaveTokensRescued(address from, address indexed to, uint256 amount);
 
+  /**
+   * @dev thrown when the migration is closed
+   */
+  error MigrationClosed();
+
+  /**
+   * @dev thrown when the specified recipient is invalid
+   */
+  error InvalidRecipient();
+
   /**
    * @param aave the address of the AAVE token
    * @param lend the address of the LEND token
    * @param lendAaveRatio the exchange rate between LEND and AAVE
    */
-  constructor(IERC20 aave, IERC20 lend, uint256 lendAaveRatio) public {
+  constructor(IERC20 aave, IERC20 lend, uint256 lendAaveRatio) {
     AAVE = aave;
     LEND = lend;
     LEND_AAVE_RATIO = lendAaveRatio;
@@ -46,68 +59,32 @@ contract LendToAaveMigrator is VersionedInitializable {
   }
 
   /**
-   * @dev initializes the implementation and rescues the LEND sent to the contract
-   * by migrating them to AAVE and sending them to the AaveMerkleDistributor
-   * and then burning the LEND tokens
-   * @param aaveMerkleDistributor address of the AAVE rescue distributor
-   * @param lendToMigratorAmount amount of lend sent to migrator that need to be rescued
-   * @param lendToLendAmount amount of lend sent to LEND that need to be rescued
-   * @param lendToAaveAmount amount of lend sent to AAVE that need to be rescued
+   * @dev recovers all the AAVE in this contract and send it to the given address.
    */
-  function initialize(
-    address aaveMerkleDistributor,
-    uint256 lendToMigratorAmount,
-    uint256 lendToLendAmount,
-    uint256 lendToAaveAmount
-  ) public initializer {
-    uint256 lendAmount = lendToMigratorAmount + lendToLendAmount + lendToAaveAmount;
-    uint256 migratorLendBalance = _totalLendMigrated + lendToMigratorAmount;
-
-    // account for the LEND sent to the contract for the total migration
-    _totalLendMigrated += lendAmount;
-
-    // transfer AAVE + LEND sent to this contract
-    uint256 amountToRescue = lendAmount / LEND_AAVE_RATIO;
-    AAVE.transfer(aaveMerkleDistributor, amountToRescue);
-
-    LEND.transfer(address(LEND), migratorLendBalance);
-
-    emit LendMigrated(address(this), lendAmount);
-    emit AaveTokensRescued(address(this), aaveMerkleDistributor, amountToRescue);
-
-    // checks that the amount of AAVE not migrated is less or equal as the amount of AAVE disposable for migration
-    // we have found that there was a previous small surplus on the AAVE token amount found on the LendToAaveMigrator
-    // contract previous to the rescue, that is why we need to use <= instead of == . This amount is 582968318731898974 (0,58 AAVE)
-    require(
-      (LEND.totalSupply() - LEND.balanceOf(address(LEND)) - lendToAaveAmount) / LEND_AAVE_RATIO <=
-        AAVE.balanceOf(address(this)),
-      'INCORRECT_BALANCE_RESCUED'
-    );
+  function initialize(address recipient) public initializer {
+    require(recipient != address(0), InvalidRecipient());
+
+    uint256 currentBalance = AAVE.balanceOf(address(this));
+    AAVE.safeTransfer(recipient, currentBalance);
+
+    emit AaveTokensRescued(address(this), recipient, currentBalance);
   }
 
   /**
    * @dev returns true if the migration started
    */
-  function migrationStarted() external view returns (bool) {
-    return lastInitializedRevision != 0;
+  function migrationStarted() external pure returns (bool) {
+    return false;
   }
 
   /**
    * @dev executes the migration from LEND to AAVE. Users need to give allowance to this contract to transfer LEND before executing
    * this transaction.
    * burns the migrated LEND amount
-   * @param amount the amount of LEND to be migrated
    */
-  function migrateFromLEND(uint256 amount) external {
-    require(lastInitializedRevision != 0, 'MIGRATION_NOT_STARTED');
-
-    _totalLendMigrated = _totalLendMigrated + amount;
-    LEND.transferFrom(msg.sender, address(this), amount);
-    AAVE.transfer(msg.sender, amount / LEND_AAVE_RATIO);
-
-    LEND.transfer(address(LEND), amount);
-
-    emit LendMigrated(msg.sender, amount);
+  function migrateFromLEND(uint256 amount) external pure {
+    amount;
+    revert MigrationClosed();
   }
 
   /**
