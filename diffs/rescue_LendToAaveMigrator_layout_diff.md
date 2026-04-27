```diff
diff --git a/reports/LendToAaveMigrator_layout.md b/reports/rescue_LendToAaveMigrator_layout.md
index b6ab31f..a8e5587 100644
--- a/reports/LendToAaveMigrator_layout.md
+++ b/reports/rescue_LendToAaveMigrator_layout.md
@@ -1,7 +1,7 @@

-| Name                    | Type        | Slot | Offset | Bytes | Contract                                                                             |
-|-------------------------|-------------|------|--------|-------|--------------------------------------------------------------------------------------|
-| lastInitializedRevision | uint256     | 0    | 0      | 32    | etherscan/LendToAaveMigrator/src/contracts/LendToAaveMigrator.sol:LendToAaveMigrator |
-| ______gap               | uint256[50] | 1    | 0      | 1600  | etherscan/LendToAaveMigrator/src/contracts/LendToAaveMigrator.sol:LendToAaveMigrator |
-| _totalLendMigrated      | uint256     | 51   | 0      | 32    | etherscan/LendToAaveMigrator/src/contracts/LendToAaveMigrator.sol:LendToAaveMigrator |
+| Name                    | Type        | Slot | Offset | Bytes | Contract                                      |
+|-------------------------|-------------|------|--------|-------|-----------------------------------------------|
+| lastInitializedRevision | uint256     | 0    | 0      | 32    | src/LendToAaveMigrator.sol:LendToAaveMigrator |
+| ______gap               | uint256[50] | 1    | 0      | 1600  | src/LendToAaveMigrator.sol:LendToAaveMigrator |
+| _totalLendMigrated      | uint256     | 51   | 0      | 32    | src/LendToAaveMigrator.sol:LendToAaveMigrator |

```
