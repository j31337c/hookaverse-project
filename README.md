## Hookaverse

** Hookaverse is a broader ecosystem or frontend for HookFi built with Next.js

Hookaverse Developer Environment:

- **Foundry**: Used for developing and testing smart contracts (e.g. the OnsidedUSDCHook)
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
```
