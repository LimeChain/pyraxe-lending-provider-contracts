# Mutuum Lending Provider Contracts

This repository is a fork of [Aave Protocol V2](https://github.com/aave/protocol-v2) that has been customized to deploy the **Pyraxe** lending market on the **Sepolia** testnet. This document describes all the modifications, configurations, and additional logic that were implemented to enable this deployment.

## Table of Contents

1. [Overview](#overview)
2. [Key Modifications](#key-modifications)
3. [Market Configuration](#market-configuration)
4. [Additional Contracts](#additional-contracts)
5. [Sepolia Network Configuration](#sepolia-network-configuration)
6. [Deployment Scripts](#deployment-scripts)
7. [Deployment Process](#deployment-process)
8. [Contract Addresses](#contract-addresses)
9. [Adding a New Reserve Token](#adding-a-new-reserve-token-to-the-lending-pool)
10. [Verification](#verification)

## Overview

This fork extends the Aave Protocol V2 codebase to support:

- **Pyraxe Market**: A custom lending market configuration
- **Sepolia Testnet**: Full deployment support for Ethereum Sepolia testnet
- **Pyth Fallback Oracle**: Enhanced oracle infrastructure using Pyth Network as a fallback price feed
- **Fee Collector**: Custom protocol fee collection contract with role-based access control

## Key Modifications

### 1. Market Configuration

A new market configuration was added at `markets/pyraxe/`:

- **`markets/pyraxe/index.ts`**: Main Pyraxe market configuration
- **`markets/pyraxe/commons.ts`**: Common configuration parameters including Pyth Oracle and Fee Collector settings
- **`markets/pyraxe/reservesConfigs.ts`**: Reserve asset configurations

The Pyraxe market is configured with a subset of assets for Sepolia:

- **WBTC** (Wrapped Bitcoin)
- **WETH** (Wrapped Ethereum)
- **USDT** (Tether)

### 2. Configuration Registration

The Pyraxe market was registered in the configuration system:

**File**: `helpers/configuration.ts`

```typescript
export enum ConfigNames {
  Commons = 'Commons',
  Aave = 'Aave',
  Matic = 'Matic',
  Amm = 'Amm',
  Avalanche = 'Avalanche',
  Pyraxe = 'Pyraxe', // Added
}
```

### 3. Type Definitions

New interfaces were added to support Pyth Oracle and Fee Collector:

**File**: `helpers/types.ts`

```typescript
export interface IPythOracleParams {
  [network: string]: {
    pythAddress: tEthereumAddress;
    initialStaleTime: number;
  };
}

export interface IFeeCollectorParams {
  [network: string]: {
    admin: tEthereumAddress;
    guardian: tEthereumAddress;
    withdrawer: tEthereumAddress;
  };
}
```

## Market Configuration

### Pyraxe Market Settings

**Location**: `markets/pyraxe/index.ts`

```typescript
export const PyraxeConfig: IAaveConfiguration = {
  ...CommonsConfig,
  MarketId: 'Pyraxe market',
  ProviderId: 1,
  ReservesConfig: {
    USDT: strategyUSDT,
    WBTC: strategyWBTC,
    WETH: strategyWETH,
  },
  // ... additional configuration
};
```

### Sepolia Network Assets

**Location**: `markets/pyraxe/index.ts`

The following asset addresses are configured for Sepolia:

```typescript
[eEthereumNetwork.sepolia]: {
  WBTC: '0x29f2D40B0605204364af54EC677bD022dA425d03',
  WETH: '0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c',
  USDT: '0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0',
}
```

### Pyth Oracle Configuration

**Location**: `markets/pyraxe/commons.ts`

```typescript
PythOracle: {
  [eEthereumNetwork.sepolia]: {
    pythAddress: '0xDd24F84d36BF92C65F92307595335bdFab5Bbd21',
    initialStaleTime: 120, // 120 seconds staleness check
  },
}
```

### Fee Collector Configuration

**Location**: `markets/pyraxe/commons.ts`

```typescript
FeeCollector: {
  [eEthereumNetwork.sepolia]: {
    admin: '0xB33Ab79988Bcd11Ff0E98Dd7813f0a6a4555C91C',
    guardian: '0xB33Ab79988Bcd11Ff0E98Dd7813f0a6a4555C91C',
    withdrawer: '0xB33Ab79988Bcd11Ff0E98Dd7813f0a6a4555C91C',
  },
}
```

## Additional Contracts

### 1. Pyth Fallback Oracle

**Location**: `contracts/pyraxe/contracts/PythFallbackOracle.sol`

A custom fallback oracle implementation that integrates with Pyth Network for price feeds.

#### Key Features:

- **Staleness Protection**: Configurable staleness time (default: 120 seconds)
- **Price Feed Mapping**: Flexible asset-to-asset price conversion using Pyth feed IDs
- **Precision Handling**: Proper conversion of Pyth's exponential price format to target asset decimals
- **Admin Controls**: Owner can set price feeds and adjust staleness parameters

#### Integration:

The Pyth Oracle is deployed during the oracle deployment phase and set as the fallback oracle for the AaveOracle contract.

### 2. Fee Collector

**Location**: `contracts/pyraxe/contracts/FeeCollector.sol`

A custom protocol fee collection contract with enhanced security features.

#### Key Features:

- **Role-Based Access Control**: Three distinct roles (Admin, Guardian, Withdrawer)
- **Two-Step Withdrawal**: 24-hour cooldown period for withdrawals
- **Guardian Veto**: Guardian can cancel withdrawal requests during cooldown
- **Security Model**: Prevents single-point-of-failure attacks

#### Roles:

- **Admin**: Manages access control (typically a multisig)
- **Withdrawer**: Can initiate and claim withdrawals after cooldown
- **Guardian**: Can veto withdrawal requests during cooldown period

#### Integration:

The Fee Collector is deployed during the initialization phase and used as the treasury address for reserve factors.

## Sepolia Network Configuration

### Hardhat Configuration

**File**: `hardhat.config.ts`

Sepolia network was added to the Hardhat configuration:

```typescript
networks: {
  sepolia: getCommonNetworkConfig(eEthereumNetwork.sepolia, 11155111),
  // ... other networks
}
```

### Network Type Definition

**File**: `helpers/types.ts`

Sepolia was added to the network enum:

```typescript
export enum eEthereumNetwork {
  // ... other networks
  sepolia = 'sepolia',
}
```

### Helper Configuration

**File**: `helper-hardhat-config.ts`

Sepolia RPC URL and gas settings were configured:

```typescript
export const NETWORKS_RPC_URL: iParamsPerNetwork<string> = {
  // ... other networks
  [eEthereumNetwork.sepolia]: process.env.SEPOLIA_RPC_URL || '',
};

export const NETWORKS_DEFAULT_GAS: iParamsPerNetwork<number | 'auto'> = {
  // ... other networks
  [eEthereumNetwork.sepolia]: 'auto',
};
```

## Deployment Scripts

### Sequential Deployment Flow

The deployment follows a sequential execution pattern in the `tasks/full/` directory:

#### 1. Address Provider Registry

**File**: `tasks/full/0_address_provider_registry.ts`

- Deploys the LendingPoolAddressesProviderRegistry
- Task: `full:deploy-address-provider-registry`

#### 2. Address Provider

**File**: `tasks/full/1_address_provider.ts`

- Deploys the LendingPoolAddressesProvider
- Sets pool admin and emergency admin
- Registers with the provider registry
- Task: `full:deploy-address-provider`

#### 3. Lending Pool

**File**: `tasks/full/2_lending_pool.ts`

- Deploys the LendingPool implementation
- Deploys the LendingPoolConfigurator
- Sets up proxy contracts
- Task: `full:deploy-lending-pool`

#### 4. Oracles

**File**: `tasks/full/3_oracles.ts`

- **Custom Addition**: Deploys Pyth Fallback Oracle
- Deploys AaveOracle with Pyth as fallback
- Deploys LendingRateOracle
- Registers oracles with AddressesProvider
- Task: `full:deploy-oracles`

**Key Modification**: The oracle deployment task was modified to:

1. Deploy the Pyth Fallback Oracle using the custom task `deploy-pyraxe-pyth-oracle`
2. Use the deployed Pyth Oracle address as the fallback oracle for AaveOracle

#### 5. Data Provider

**File**: `tasks/full/4_data-provider.ts`

- Deploys AaveProtocolDataProvider
- Task: `full:data-provider`

#### 6. WETH Gateway

**File**: `tasks/full/5-deploy-wethGateWay.ts`

- Deploys WETHGateway
- Authorizes gateway with lending pool
- Task: `full-deploy-weth-gateway`

#### 7. Initialize Lending Pool

**File**: `tasks/full/6-initialize.ts`

- **Custom Addition**: Deploys Fee Collector
- Initializes reserve assets (aTokens, debt tokens)
- Configures reserve parameters
- Deploys CollateralManager
- Task: `full:initialize-lending-pool`

**Key Modification**: The initialization task was modified to:

1. Deploy the Fee Collector using the custom task `deploy-pyraxe-feecollector`
2. Use the Fee Collector address as the treasury address for reserve factors

### Custom Deployment Tasks

**File**: `tasks/deployments/pyraxe-deployments.ts`

Two custom tasks were added:

#### 1. Deploy Pyth Oracle

```typescript
task('deploy-pyraxe-pyth-oracle', 'Deploys the Pyraxe Pyth Fallback Oracle')
  .addFlag('verify', 'Verify contract at Etherscan')
  .addParam('pool', 'Pool configuration name');
```

This task:

- Loads Pyth Oracle configuration from pool config
- Deploys PythFallbackOracle contract

#### 2. Deploy Fee Collector

```typescript
task('deploy-pyraxe-feecollector', 'Deploys the Pyraxe Fee Collector')
  .addFlag('verify', 'Verify contract at Etherscan')
  .addParam('pool', 'Pool configuration name');
```

This task:

- Loads Fee Collector configuration from pool config
- Deploys FeeCollector contract with admin, guardian, and withdrawer roles

### Deployment Helper Functions

**File**: `tasks/helpers/contracts-deployments.ts`

Added deployment helper functions:

```typescript
export const deployPythOracle = async (
  args: (string | number)[],
  verify?: boolean
): Promise<PythFallbackOracle>

export const deployFeeCollector = async (
  args: string[],
  verify?: boolean
): Promise<FeeCollector>

export const getPythOracle = async (address?: tEthereumAddress)
export const getFeeCollector = async (address?: tEthereumAddress)
```

## Deployment Process

### Prerequisites

Set up environment variables in `.env`:

```bash
MNEMONIC=
ALCHEMY_KEY=
ETHERSCAN_KEY=
```

## Build and deploy commands

### Docker commands

```bash
docker-compose build
```

```bash
docker-compose up -d
```

```bash
docker compose exec contracts-env bash
```

### Contract steps

Compile contracts

```bash
npm run compile
```

### Deploy steps

Deploy Address Provider Registry

```bash
npx hardhat full:deploy-address-provider-registry --network sepolia --pool Pyraxe
```

Deploy Address Provider

```bash
npx hardhat full:deploy-address-provider --network sepolia --pool Pyraxe
```

Deploy Lending Pool

```bash
npx hardhat full:deploy-lending-pool --network sepolia --pool Pyraxe
```

Deploy Oracles

```bash
npx hardhat full:deploy-oracles --network sepolia --pool Pyraxe
```

Deploy Data Provider

```bash
npx hardhat full:data-provider --network sepolia
```

Deploy WETH Gateway

```bash
npx hardhat full-deploy-weth-gateway --network sepolia --pool Pyraxe
```

Initialize Lending Pool

```bash
npx hardhat full:initialize-lending-pool --network sepolia --pool Pyraxe
```

Deploy Ui Pool Data Provider

```bash
npx hardhat deploy-UiPoolDataProviderV2V3 --network sepolia
```

Deploy Ui Incentive Data Provider

```bash
npx hardhat deploy-UiIncentiveDataProviderV2V3 --network sepolia
```

## Contract Addresses

After deployment, contract addresses are stored in the `deployment-contracts.json` file. You can find all deployed contract addresses there. Key contracts include:

- **LendingPoolAddressesProvider**: Core address registry
- **LendingPool**: Main lending pool contract
- **LendingPoolConfigurator**: Configuration contract (proxy)
- **AaveOracle**: Price oracle with Pyth fallback
- **PythFallbackOracle**: Pyth Network integration
- **FeeCollector**: Protocol fee collection (treasury)
- **WETHGateway**: Wrapped ETH gateway
- **UiPoolDataProvider**: UI data provider contract
- **aTokens**: Interest-bearing tokens for each reserve
- **Debt Tokens**: Stable and variable debt tokens

> **Note**: All contract addresses can be found in `deployment-contracts.json` after deployment, or by checking the deployment console output.

---

## Adding a New Reserve Token to the Lending Pool

This guide demonstrates how to add a new token (using **LINK** as an example) to the Pyraxe lending pool after the initial deployment. This process involves 5 sequential steps that must be completed in order.

### Prerequisites

Before starting, ensure you have:

- ✅ All core contracts deployed (from the deployment steps above)
- ✅ Access to Etherscan for the Sepolia network
- ✅ The following contract addresses from `deployment-contracts.json`:
  - `LendingPoolConfigurator` (proxy address)
  - `LendingPoolAddressesProvider`
  - `AaveOracle`
  - `UiPoolDataProvider`
  - `FeeCollector` (treasury address)
- ✅ Token implementation addresses (can reuse from existing reserves like WETH):
  - `AToken` implementation
  - `StableDebtToken` implementation
  - `VariableDebtToken` implementation
- ✅ Chainlink price feed address for the token (e.g., LINK/ETH feed)

### Step 1: Initialize the Reserve Token

This step creates the aToken, stable debt token, and variable debt token proxies for your new asset.

#### 1.1 Access LendingPoolConfigurator on Etherscan

1. Navigate to Etherscan (Sepolia) and search for the **LendingPoolConfigurator** address
2. Go to the **Contract** tab
3. Click **More Options** → **Is this a proxy?** → **Verify**
4. Select **Write as Proxy** (this is required because `LendingPoolConfigurator` is a proxy contract)

> **Important**: Always interact with the proxy contract, not the implementation. Calling functions directly on the implementation will revert for security reasons.

#### 1.2 Call `batchInitReserve` Function

Navigate to the **Write Contract** section and call the `batchInitReserve` function with the following parameters:

| Parameter                       | Type      | Description                                           | Example Value (LINK)                         |
| ------------------------------- | --------- | ----------------------------------------------------- | -------------------------------------------- |
| **aTokenImpl**                  | `address` | Logic contract for aTokens (reuse from WETH)          | `0xE66a8df05aBf119c8dBc08AaA6a38A46e948A62f` |
| **stableDebtTokenImpl**         | `address` | Logic for stable debt tokens (reuse)                  | `0xe5E43f6327f08879bbf2302f17302A65702B4E2d` |
| **variableDebtTokenImpl**       | `address` | Logic for variable debt tokens (reuse)                | `0xe68451E184e3C10f95663130D600fc4b3C176a2D` |
| **underlyingAssetDecimals**     | `uint8`   | Decimals of the token                                 | `18`                                         |
| **interestRateStrategyAddress** | `address` | Strategy contract (reuse WETH strategy or deploy new) | `0x8877E27C326ae220089a322F56F2Fdde38a2d2b5` |
| **underlyingAsset**             | `address` | The token address to list                             | `0xf8Fb3713D459D7C1018BD0A49D19b4C44290EBE5` |
| **treasury**                    | `address` | Fee collector address                                 | `0x7530E19c719B63aaD05068CfF2593BF93cACdDc6` |
| **incentivesController**        | `address` | Reward distributor (use zero address if none)         | `0x0000000000000000000000000000000000000000` |
| **aTokenName**                  | `string`  | Name for the receipt token                            | `"Pyraxe Interest Bearing LINK"`             |
| **aTokenSymbol**                | `string`  | Symbol for receipt token                              | `"mtLINK"`                                   |
| **variableDebtTokenName**       | `string`  | Name for variable debt token                          | `"Pyraxe Variable Debt LINK"`                |
| **variableDebtTokenSymbol**     | `string`  | Symbol for variable debt token                        | `"variableDebtmtLINK"`                       |
| **stableDebtTokenName**         | `string`  | Name for stable debt token                            | `"Pyraxe Stable Debt LINK"`                  |
| **stableDebtTokenSymbol**       | `string`  | Symbol for stable debt token                          | `"stableDebtmtLINK"`                         |
| **params**                      | `bytes`   | Extra initialization data (usually empty)             | `0x`                                         |

#### 1.3 Example Input Array

For the LINK token example, the complete input array would be:

```json
[
  [
    "0xE66a8df05aBf119c8dBc08AaA6a38A46e948A62f",
    "0xe5E43f6327f08879bbf2302f17302A65702B4E2d",
    "0xe68451E184e3C10f95663130D600fc4b3C176a2D",
    "18",
    "0x8877E27C326ae220089a322F56F2Fdde38a2d2b5",
    "0xf8Fb3713D459D7C1018BD0A49D19b4C44290EBE5",
    "0x7530E19c719B63aaD05068CfF2593BF93cACdDc6",
    "0x0000000000000000000000000000000000000000",
    "ChainLink",
    "Pyraxe Interest Bearing LINK",
    "mtLINK",
    "Pyraxe Variable Debt LINK",
    "variableDebtmtLINK",
    "Pyraxe Stable Debt LINK",
    "stableDebtmtLINK",
    "0x"
  ]
]
```

> **Note**: The function accepts an array of arrays, allowing you to initialize multiple reserves in a single transaction. For a single token, wrap the parameters in an additional array.

#### 1.4 Verify Reserve Initialization

After the transaction is confirmed:

1. Go to the **UiPoolDataProvider** contract on Etherscan
2. Call `getReservesList(address provider)` with the **LendingPoolAddressesProvider** address
3. Verify that your new token address appears in the returned list
4. Compare the token details to ensure everything was set correctly

---

### Step 2: Configure Price Oracle

**Critical**: This step must be completed before any deposits. Without a price feed, deposits will fail or health factors will be incorrect.

#### 2.1 Find the AaveOracle Contract

1. Locate the **AaveOracle** contract address from `deployment-contracts.json`
2. Navigate to the contract on Etherscan
3. Go to the **Write Contract** section

#### 2.2 Set Asset Price Source

Call the `setAssetSources` function with:

- **assets** (array): `[LINK_TOKEN_ADDRESS]`
- **sources** (array): `[CHAINLINK_PRICE_FEED_ADDRESS]`

Example for LINK:

- **assets**: `["0xf8Fb3713D459D7C1018BD0A49D19b4C44290EBE5"]`
- **sources**: `["CHAINLINK_LINK_ETH_FEED_ADDRESS"]`

> **Note**: The price feed should be the Chainlink aggregator for the token/ETH pair (e.g., LINK/ETH). Find the correct Chainlink feed address for Sepolia testnet.

#### 2.3 Verify Oracle Configuration

After setting the price source, you can verify by calling `getAssetPrice(address asset)` on the AaveOracle contract with your token address. It should return a non-zero price.

---

### Step 3: Enable Collateral Usage

This step defines the risk parameters for using the token as collateral.

#### 3.1 Configure Collateral Parameters

On the **LendingPoolConfigurator** contract (Write as Proxy), call:

**Function**: `configureReserveAsCollateral(address asset, uint256 ltv, uint256 liquidationThreshold, uint256 liquidationBonus)`

**Parameters**:

| Parameter                | Type      | Description                             | Example Value (LINK)                         |
| ------------------------ | --------- | --------------------------------------- | -------------------------------------------- |
| **asset**                | `address` | The token address                       | `0xf8Fb3713D459D7C1018BD0A49D19b4C44290EBE5` |
| **ltv**                  | `uint256` | Loan-to-Value ratio (in basis points)   | `7000` (70.00%)                              |
| **liquidationThreshold** | `uint256` | Liquidation threshold (in basis points) | `7500` (75.00%)                              |
| **liquidationBonus**     | `uint256` | Liquidation bonus (in basis points)     | `10500` (105.00%)                            |

**Parameter Explanations**:

- **LTV (7000)**: Maximum percentage of collateral value that can be borrowed (70%)
- **Liquidation Threshold (7500)**: If debt reaches 75% of collateral value, the position becomes liquidatable
- **Liquidation Bonus (10500)**: Liquidators receive a 5% bonus (use 10500, not 500)

> **Important**: Values are in basis points (1 basis point = 0.01%). For example, 7000 = 70.00%.

---

### Step 4: Enable Borrowing

After completing the previous steps, users can deposit the token, but borrowing must be explicitly enabled.

#### 4.1 Enable Borrowing Function

On the **LendingPoolConfigurator** contract (Write as Proxy), call:

**Function**: `enableBorrowingOnReserve(address asset, bool stableBorrowRateEnabled)`

**Parameters**:

| Parameter                   | Type      | Description                  | Example Value (LINK)                         |
| --------------------------- | --------- | ---------------------------- | -------------------------------------------- |
| **asset**                   | `address` | The token address            | `0xf8Fb3713D459D7C1018BD0A49D19b4C44290EBE5` |
| **stableBorrowRateEnabled** | `bool`    | Enable stable borrowing rate | `false`                                      |

> **Note**: Setting `stableBorrowRateEnabled` to `false` means only variable rate borrowing is available, which is standard for most volatile assets.

---

### Step 5: Set Reserve Factor

The reserve factor determines what percentage of interest paid by borrowers goes to the protocol treasury versus liquidity providers.

#### 5.1 Set Reserve Factor

On the **LendingPoolConfigurator** contract (Write as Proxy), call:

**Function**: `setReserveFactor(address asset, uint256 reserveFactor)`

**Parameters**:

| Parameter         | Type      | Description                      | Example Value (LINK)                         |
| ----------------- | --------- | -------------------------------- | -------------------------------------------- |
| **asset**         | `address` | The token address                | `0xf8Fb3713D459D7C1018BD0A49D19b4C44290EBE5` |
| **reserveFactor** | `uint256` | Reserve factor (in basis points) | `1000` (10.00%)                              |

**Common Reserve Factor Values**:

- **Stablecoins**: `1000` (10%)
- **Volatile assets**: `1000-2000` (10-20%)
- **High-risk assets**: `2000-3500` (20-35%)

> **Note**: The reserve factor is in basis points. 1000 = 10.00% of interest goes to the treasury.

---

### Verification Checklist

After completing all 5 steps, verify the following:

- [ ] Reserve appears in `getReservesList()` from UiPoolDataProvider
- [ ] Price oracle returns a valid price for the asset
- [ ] Collateral parameters are set correctly (LTV, liquidation threshold, bonus)
- [ ] Borrowing is enabled
- [ ] Reserve factor is set
- [ ] Users can deposit the token
- [ ] Users can borrow the token (if enabled)
- [ ] Token can be used as collateral

### Troubleshooting

**Issue**: Transaction reverts when calling `batchInitReserve`

- **Solution**: Ensure you're calling through the proxy contract, not the implementation

**Issue**: Deposits fail or health factors are incorrect

- **Solution**: Verify the price oracle is configured (Step 2)

**Issue**: Token cannot be used as collateral

- **Solution**: Verify collateral parameters are set (Step 3)

**Issue**: Borrowing is not available

- **Solution**: Verify borrowing is enabled (Step 4)

## Verification

After deployment, verify contracts on Etherscan to ensure transparency and security.

### Verify All Contracts

```bash
# Verify all contracts
npx hardhat --network sepolia verify:general --all --pool Pyraxe

# Verify tokens (aTokens and debt tokens)
npx hardhat --network sepolia verify:tokens --pool Pyraxe
```

### Manual Verification

1. Navigate to [Etherscan Sepolia](https://sepolia.etherscan.io/)
2. Search for each deployed contract address
3. Click **Contract** → **Verify and Publish**
4. Fill in the contract details and verify

### Key Contracts to Verify

- LendingPoolAddressesProvider
- LendingPool
- LendingPoolConfigurator
- AaveOracle
- PythFallbackOracle
- FeeCollector
- WETHGateway
- UiPoolDataProvider
- All aTokens and debt tokens
