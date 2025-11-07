## Modular Contracts
> A unified, permissionless interface for seamless interaction with liquidity pools — by [Zup Protocol](https://zupprotocol.xyz)


[![Lint](https://github.com/Zup-Protocol/modular-contracts/actions/workflows/lint.yml/badge.svg?branch=main)](https://github.com/Zup-Protocol/modular-contracts/actions/workflows/lint.yml) [![Test](https://github.com/Zup-Protocol/modular-contracts/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/Zup-Protocol/modular-contracts/actions/workflows/test.yml) [![Static Analysis](https://github.com/Zup-Protocol/modular-contracts/actions/workflows/static-analysis.yml/badge.svg?branch=main)](https://github.com/Zup-Protocol/modular-contracts/actions/workflows/static-analysis.yml)

Modular Contracts are a set of smart contracts developed by _[Zup Protocol](https://zupprotocol.xyz)_ that provide a unified interface for interacting with liquidity pools across multiple decentralized exchange protocols.

They enable integrators to seamlessly interact with different AMM architectures (e.g., _[Uniswap V3](https://blog.uniswap.org/uniswap-v3)_, _[Algebra](https://algebra.finance/)_, _[PancakeSwap Infinity](https://docs.pancakeswap.finance/trade/pancakeswap-infinity)_, etc.) through a consistent and predictable interface. Each protocol integration is implemented as an independent module, responsible for defining the logic of its specific actions (such as adding or removing liquidity) while maintaining a standardized function signature across all modules.

Modules are **standalone**, **immutable**, and **permissionless**, they can be deployed and used in any environment by anyone. The `Modular` contract serves as the registry and manager for all module versions, ensuring consistent usage across the ecosystem.

Unlike modules, only authorized users can update the module registry in the `Modular` contract and define which versions are currently used. To enhance security and transparency, any change to the officially used modules is subject to a **7-day activation** delay before being able to be activated.

⚠️ **This project is under active development and has not yet been audited. Production use is strongly discouraged, as the code may contain bugs or vulnerabilities.**

## Development Setup

To contribute, test, or run this project locally, you’ll need the following tools installed:

### 🧱 Required Dependencies

#### Foundry
Used as a framework for smart contract development, testing, and deployment.

- **Check installation**
  ```bash
  forge --version
  ```
- **Install (if missing)**: https://getfoundry.sh/introduction/installation/

#### Node.js (>= v20)
Required for linters and development utilities.

- **Check installation**
  ```bash
  node --version
  ```
- **Install / Update**: https://nodejs.org/en/download/

#### Yarn (>= v4)
Package manager for JavaScript dependencies.

- **Check installation**
  ```bash
  yarn --version
  ```
- **Install**: https://yarnpkg.com/getting-started/install


### 🧪 Recommended Tooling
These tools enhance the development experience and improve security analysis, but are optional.

#### Vulnerability Scanner
Tools for detecting vulnerabilities in smart contracts:

##### Slither
- Install: https://github.com/crytic/slither#how-to-install

##### Aderyn
- Install CLI: https://cyfrin.gitbook.io/cyfrin-docs/aderyn-cli/installation  
- Install VSCode extension: https://cyfrin.gitbook.io/cyfrin-docs/aderyn-vs-code/installation-and-usage

#### Code Formatter

##### Prettier
- Install CLI: https://prettier.io/docs/en/install.html
- Install VSCode extension: https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode

## Getting Started

**Clone the repository and setup the environment:**

```bash
git clone https://github.com/Zup-Protocol/modular-contracts.git
cd modular-contracts
yarn install
forge build
```

Run the test suite:

```bash
yarn test
```

Run the linter:

```bash
yarn lint
```

This command will run solhint linter to check for linting errors in the `src` folder.

## 📦 Deploying Contracts
Note that all commands will by default use a Trezor device to sign the transaction, if you want to use a different device please modify the script
at the [package.json](package.json) file to specify your preferred signing method, according to the forge options.

All commands will also try to verify the contract after deployment, to do so you should set the `ETHERSCAN_API_KEY` in the [.env](.env) file. To obtain an API key, check out [Getting an API Key](https://docs.etherscan.io/getting-an-api-key) from Etherscan Docs.

##### Deploying the `Modular` contract

To deploy the `Modular` contract, use the following command at the root of the repository in your terminal:

```bash
yarn deploy:Modular [network]
```

This command deploys the `Modular` contract to the specified network. The `network` is required and can be one of the defined networks in the [foundry.toml](foundry.toml) file, under the `rpc_endpoints` section.


##### Deploying the `UniswapV3PoolModule` contract

To deploy the `UniswapV3PoolModule` contract, use the following command at the root of the repository in your terminal:

```bash
yarn deploy:UniswapV3PoolModule [network]
```

this command deploys the `UniswapV3PoolModule` contract to the specified network. The `network` is required and can be one of the defined networks in the [foundry.toml](foundry.toml) file, under the `rpc_endpoints` section.


## 🗂 Repository Structure
```bash
src/ # Core smart contracts
├── modules/ # Individual liquidity pool modules
├── libraries/ # Shared utilities
├── interfaces/ # Smart contract interfaces
└── Modular.sol # Module registry and entry point

script/ # Deployment and management scripts
test/ # Test suites
```

## 📝 License

This project is released under the [GNU General Public License v3](LICENSE).