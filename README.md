# Lend Migrator Rescue

Rescue the residual AAVE held by the legacy `LendToAaveMigrator` proxy and permanently close the LEND → AAVE migration via an Aave Governance V3 proposal.

## Background

The original `LendToAaveMigrator` proxy at [`0x317625234562B1526Ea2FaC4030Ea499C5291de4`](https://etherscan.io/address/0x317625234562B1526Ea2FaC4030Ea499C5291de4) still holds AAVE tokens that were never migrated. The LEND → AAVE migration is no longer needed: this repo upgrades the proxy to a new implementation that sweeps the residual AAVE to the Aave Collector and disables the migration entry point.

## Contracts

Two contracts in `src/`:

### `src/LendToAaveMigrator.sol`

New `REVISION = 3` implementation of the migrator.

- `initialize()` — one-shot, gated by `VersionedInitializable`. Transfers the proxy's full AAVE balance to `COLLECTOR` and emits `AaveTokensRescued`.
- `migrateFromLEND(uint256)` — always reverts with `MigrationClosed()`. The migration is permanently shut.
- `migrationEnded()` — returns `true`.
- Constructor wires the immutables (`AAVE`, `LEND`, `LEND_AAVE_RATIO`, `COLLECTOR`) and disables initializers on the implementation itself by setting `lastInitializedRevision = REVISION`.

### `src/proposals/ProposalPayload.sol`

Aave Governance V3 payload (`IProposalGenericExecutor`).

`execute()` calls `ProxyAdmin.upgradeAndCall` on the migrator proxy with the new implementation and `abi.encodeWithSignature('initialize()')`, so the upgrade and the rescue happen atomically in the same transaction.

## Upgrade flow

1. Deploy the new `LendToAaveMigrator` implementation (see `scripts/DeployLendToAaveMigrator.s.sol`).
2. Deploy `ProposalPayload` with the new implementation address.
3. Aave Governance V3 executes the payload → `ProxyAdmin.upgradeAndCall` upgrades the migrator proxy and calls `initialize()` in the same transaction.
4. `initialize()` sweeps the proxy's AAVE balance to the Aave Collector.
5. From this point on, `migrateFromLEND` reverts and the migration is closed.

## Install

Requires [Foundry](https://book.getfoundry.sh/) (`forge`, `cast`) and Node + Yarn (only for the prettier/lint scripts).

```bash
git submodule update --init --recursive
forge install
yarn install
```

## Tests

```bash
forge test -vvv
# or
make test
```

Test files live in `tests/`: `LendToAaveMigrator.t.sol` and `ProposalPayload.t.sol`.

## Storage layout & source diffs

To verify upgrade safety against the currently deployed implementation:

```bash
make download      # fetches the current on-chain implementation from Etherscan
make storage-diff  # generates storage-layout and source diffs under reports/ and diffs/
```
