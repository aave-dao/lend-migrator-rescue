// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from 'forge-std/Script.sol';
import {console} from 'forge-std/console.sol';
import {IERC20} from 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import {AaveV2EthereumAssets} from 'aave-address-book/AaveV2Ethereum.sol';
import {AaveV3Ethereum} from 'aave-address-book/AaveV3Ethereum.sol';

import {LendToAaveMigrator} from 'src/LendToAaveMigrator.sol';

contract DeployLendToAaveMigrator is Script {
  IERC20 public constant AAVE = IERC20(AaveV2EthereumAssets.AAVE_UNDERLYING);
  IERC20 public constant LEND = IERC20(0x80fB784B7eD66730e8b1DBd9820aFD29931aab03);
  uint256 public constant LEND_AAVE_RATIO = 100;
  address public constant COLLECTOR = address(AaveV3Ethereum.COLLECTOR);

  function run() external {
    vm.startBroadcast();
    LendToAaveMigrator migrator = new LendToAaveMigrator(AAVE, LEND, LEND_AAVE_RATIO, COLLECTOR);
    vm.stopBroadcast();

    console.log('LendToAaveMigrator deployed at:', address(migrator));
  }
}
