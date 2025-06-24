## Hookaverse

**Hookaverse is a broader ecosystem or frontend for HookFi built with Next.js**

Hookaverse Developer Environment:

- **Foundry**: Used for developing and testing smart contracts (e.g. the OnesidedUSDCHook)
- **Next.js**: Manages the frontend, integration with HookFi's API or contracts for token issuance and pool creation.
- **Base Network**: The target blockchain (as HookFi/Flaunch operates on Base Eth)

Objective: Create a one-sided token issuance and token USDC pool with a custom Uniswap v4 hook, restricting swaps to LPs.

Step-by-Step Setup

### Install System Dependencies

```shell
$ sudo apt update && sudo apt upgrade -y
$ sudo apt install -y build-essential curl git
```

### Install Node.js and Yarn
Next.js requires Node.js. Install Node.js 18 and Yarn:


```shell
$ curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
$ sudo apt install -y nodejs
$ npm install -g yarn
$ node -v  # Should output v18.x.x
$ yarn -v  # Should output 1.x.x
```
### Install Rust and Foundry
Foundry is written in Rust, so install Rust first, then Foundry:

### Install Rust

```shell
$ curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
$ source $HOME/.cargo/env
$ rustc --version  # Should output rustc 1.x.x
```

### Install Foundry

```shell
$ curl -L https://foundry.paradigm.xyz | bash
$ foundryup
$ forge --version  # Should output forge 0.x.x
$ cast --version   # Should output cast 0.x.x
```

### Install additional dependencies for Web3 and API integration:

```shell
$ yarn add axios ethers wagmi viem @wagmi/core @wagmi/connectors
```

### Initialize a Foundry Project
Create a Foundry project for HookFi smart contracts (e.g., the OneSidedUSDCHook) within the same repository:


```shell
$ cd ..  # Move to parent directory of hookaverse
$ forge init hookfi-contracts
$ cd hookfi-contracts
```

- Clone Uniswap v4 templete for Hook development:

```shell
git clone https://github.com/Uniswap/v4-template ../uniswap-v4-template
cp -r ../uniswap-v4-template/src/* src/
cp -r ../uniswap-v4-template/test/* test/
```

- Install Foundry dependencies (e.g., OpenZeppelin, Uniswap v4):

```shell
forge install OpenZeppelin/openzeppelin-contracts Uniswap/v4-core Uniswap/v4-periphery
```

### Set Up Environment Variables
Create .env.local in the Next.js project (hookaverse/) for frontend variables:

```shell
NEXT_PUBLIC_BASE_RPC_URL=https://sepolia.base.org  # or your Infura/Alchemy URL
NEXT_PUBLIC_FACTORY_ADDRESS=0x...  # Your OneClickUSDCFactory address (after deployment)
NEXT_PUBLIC_HOOKFI_API_URL=https://api.hookfi.gg  # Hypothetical HookFi API
NEXT_PUBLIC_USDC_ADDRESS=0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913  # Base USDC
```

Create .env in the Foundry project (hookfi-contracts/) for contract deployment:

```shell
ASE_SEPOLIA_RPC_URL=https://sepolia.base.org
PRIVATE_KEY=0x...  # Your wallet private key (never commit to Git)
```

Secure .env files:

```shell
echo ".env" >> hookfi-contracts/.gitignore
echo ".env.local" >> hookaverse/.gitignore
```

### Implement Smart Contracts

Create `OneSidedUSDCHook` and `OneClickUSDCFactory` in `hookfi-contracts/src/`:

- `src/OneSidedUSDCHook.sol`: Supports one-sided USDC liquidity and LP-only swaps.

- `src/OneClickUSDCFactory.sol`: Deploys the hook and initializes the token/USDC pool.

Create a test file in `test/OneSidedUSDCHook.t.sol`:

Compile and test contracts:

```shell
$ cd hookfi-contracts
$ forge build
$ forge test
```

### Implement Next.js Frontend
Update the Next.js project to integrate with HookFi and the custom hook. 

- Utility File: Create `hookaverse/src/lib/hookfi.js`:

- Component: Create `hookaverse/src/components/LaunchForm.js`:

- Page: Update `hookaverse/src/app/page.js`:

