# 🌉 CCIP Cross-Chain Rebase Token

A next-generation, cross-chain rebase token protocol built with [Foundry](https://github.com/foundry-rs/foundry), Solidity, and Chainlink CCIP. This project enables users to deposit ETH, receive interest-bearing rebase tokens, and seamlessly bridge their balances across multiple EVM chains—while accruing rewards everywhere.

---

## ✨ Features

- **Rebase Token:** ERC20 token with rebasing interest, accruing yield over time.
- **Vault Deposits:** Deposit ETH to mint rebase tokens; redeem tokens to withdraw ETH plus interest.
- **Cross-Chain Bridging:** Move your rebase tokens and accrued interest between chains using Chainlink CCIP.
- **Per-User Interest Rate:** Each user’s interest rate is locked at deposit and inherited on transfer/bridge.
- **Permissioned Mint/Burn:** Only protocol contracts (Vault, Pool) can mint or burn tokens.
- **Upgradeable & Auditable:** Modular, readable, and ready for audits.
- **Comprehensive Testing:** Built with Foundry’s robust test suite.

---

## 🏗️ Protocol Structure

### 1. Deposit & Mint

- Users deposit ETH into the `Vault` contract.
- The Vault mints `RebaseToken` to the user at the current global interest rate.
- Each user’s interest rate is fixed at deposit time and used to calculate their yield.

### 2. Rebasing & Interest

- User balances grow over time, reflecting accrued interest.
- The protocol owner can only decrease the global interest rate, never increase it.
- Interest is calculated per-user based on their deposit time and rate.

### 3. Redeem

- Users can redeem their `RebaseToken` for ETH at any time.
- The Vault burns the user’s tokens and sends back the principal plus accrued interest.

### 4. Cross-Chain Bridging

- Users can bridge their tokens (and accrued interest) to other EVM chains via Chainlink CCIP.
- The protocol ensures balances and interest rates are preserved across chains.

### 5. Security & Roles

- Only authorized contracts (Vault, Pool) can mint/burn tokens.
- Uses OpenZeppelin’s `Ownable` and `AccessControl` for robust permissioning.

---

## 🛠️ Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/)
- [Node.js & npm](https://nodejs.org/)
- [Git](https://git-scm.com/)

### Installation

```bash
git clone https://github.com/0xAbubakarBL/ccip-rebase-token.git
cd ccip-rebase-token
forge install
```

### Environment Setup

Copy `.env.example` to `.env` and fill in your variables as needed.

---

## 🚩 Usage

### Deploy

```bash
forge script script/Deployer.s.sol --broadcast --rpc-url <YOUR_RPC_URL>
```

### Deposit & Mint

- Send ETH to the `Vault` contract to mint `RebaseToken` at the current interest rate.

### Redeem

- Call `redeem` on the `Vault` to burn your tokens and withdraw ETH plus interest.

### Bridge

- Use the protocol’s pool contracts and Chainlink CCIP to bridge your tokens and accrued interest to other chains.

### Test

```bash
forge test
```

---

## 🧪 Testing

- All tests are in the [`test/`](test/) directory.
- Run all tests with `forge test`.

---

## 🔒 Security

- Permissioned mint/burn and role-based access control.
- Per-user interest rate prevents manipulation.
- Cross-chain logic thoroughly tested with Foundry.

---

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📄 License

This project is licensed under the MIT License.

---

## 📬 Contact

- Twitter: [@0xAbubakarBL](https://x.com/0xAbubakarBL)
- Email: 0xAbubakarBL@gmail.com

---

> Built with ❤️ using [Foundry](https://github.com/foundry-rs/foundry), [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts), and [Chainlink CCIP](https://chain.link/ccip)