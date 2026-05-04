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
  address public immutable ECOSYSTEM_RESERVE;
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
  error ZeroAddress();

  /**
   * @param aave the address of the AAVE token
   * @param lend the address of the LEND token
   * @param lendAaveRatio the exchange rate between LEND and AAVE
   * @param ecosystemReserve the address of the Ecosystem Reserve
   */
  constructor(IERC20 aave, IERC20 lend, uint256 lendAaveRatio, address ecosystemReserve) {
    require(
      address(aave) != address(0) && address(lend) != address(0) && ecosystemReserve != address(0),
      ZeroAddress()
    );

    AAVE = aave;
    LEND = lend;
    LEND_AAVE_RATIO = lendAaveRatio;
    ECOSYSTEM_RESERVE = ecosystemReserve;

    // disableInitializers on implementation
    lastInitializedRevision = REVISION;
  }

  /**
   * @dev recovers all the AAVE in this contract and send it to the ECOSYSTEM_RESERVE address
   */
  function initialize() public initializer {
    uint256 currentBalance = AAVE.balanceOf(address(this));
    AAVE.safeTransfer(ECOSYSTEM_RESERVE, currentBalance);

    emit AaveTokensRescued(address(this), ECOSYSTEM_RESERVE, currentBalance);
  }

  /**
   * @dev returns true if the migration started
   */
  function migrationStarted() external view returns (bool) {
    return lastInitializedRevision != 0;
  }

  /**
   * @dev returns true if the migration ended
   */
  function migrationEnded() external pure returns (bool) {
    return true;
  }

  /**
   * @dev executes the migration from LEND to AAVE. Users need to give allowance to this contract to transfer LEND before executing
   * this transaction.
   * Migration is closed, this function will revert if called.
   */
  function migrateFromLEND(uint256) external pure {
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
