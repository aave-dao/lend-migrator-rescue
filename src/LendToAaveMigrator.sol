// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import {VersionedInitializable} from 'src/dependencies/VersionedInitializable.sol';

/**
 * @title LendToAaveMigrator
 * @notice This contract implements the migration from LEND to AAVE token
 * @author Aave
 */
contract LendToAaveMigrator is VersionedInitializable {
  using SafeERC20 for IERC20;

  IERC20 public immutable AAVE;
  IERC20 public immutable LEND;
  uint256 public immutable LEND_AAVE_RATIO;
  uint256 public constant REVISION = 3;

  uint256 public _totalLendMigrated;

  /**
   * @dev emitted on migration
   * @param sender the caller of the migration
   * @param amount the amount being migrated
   */
  event LendMigrated(address indexed sender, uint256 indexed amount);

  /**
   * @dev emitted on token rescue when initializing
   * @param from the origin of the rescued funds
   * @param to the destination of the rescued funds
   * @param amount the amount being rescued
   */
  event AaveTokensRescued(address from, address indexed to, uint256 amount);

  /**
   * @dev thrown when the migration is closed
   */
  error MigrationClosed();

  /**
   * @dev thrown when the specified recipient is invalid
   */
  error InvalidRecipient();

  /**
   * @param aave the address of the AAVE token
   * @param lend the address of the LEND token
   * @param lendAaveRatio the exchange rate between LEND and AAVE
   */
  constructor(IERC20 aave, IERC20 lend, uint256 lendAaveRatio) {
    AAVE = aave;
    LEND = lend;
    LEND_AAVE_RATIO = lendAaveRatio;

    lastInitializedRevision = REVISION;
  }

  /**
   * @dev recovers all the AAVE in this contract and send it to the given address.
   */
  function initialize(address recipient) public initializer {
    require(recipient != address(0), InvalidRecipient());

    uint256 currentBalance = AAVE.balanceOf(address(this));
    AAVE.safeTransfer(recipient, currentBalance);

    emit AaveTokensRescued(address(this), recipient, currentBalance);
  }

  /**
   * @dev returns true if the migration started
   */
  function migrationStarted() external pure returns (bool) {
    return false;
  }

  /**
   * @dev executes the migration from LEND to AAVE. Users need to give allowance to this contract to transfer LEND before executing
   * this transaction.
   * burns the migrated LEND amount
   */
  function migrateFromLEND(uint256 amount) external pure {
    amount;
    revert MigrationClosed();
  }

  /**
   * @dev returns the implementation revision
   * @return the implementation revision
   */
  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }
}
