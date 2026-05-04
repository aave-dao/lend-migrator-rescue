// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {MiscEthereum} from 'aave-address-book/MiscEthereum.sol';

import {LendToAaveMigrator} from 'src/LendToAaveMigrator.sol';

contract DeployLendToAaveMigrator is Script {
  IERC20 public constant AAVE = IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING);
  IERC20 public constant LEND = IERC20(0x80fB784B7eD66730e8b1DBd9820aFD29931aab03);
  uint256 public constant LEND_AAVE_RATIO = 100;
  address public constant ECOSYSTEM_RESERVE = MiscEthereum.ECOSYSTEM_RESERVE;

  function run() external {
    vm.startBroadcast();
    LendToAaveMigrator migrator = new LendToAaveMigrator(
      AAVE,
      LEND,
      LEND_AAVE_RATIO,
      ECOSYSTEM_RESERVE
    );
    vm.stopBroadcast();

    console.log('LendToAaveMigrator deployed at:', address(migrator));
  }
}
