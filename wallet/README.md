# Time-Locked Wallet System - Stacks Blockchain

## Overview
This enhanced Clarity smart contract system provides secure time-locked storage for STX tokens. The system includes two main contracts: a single enhanced vault and a multi-vault manager for advanced users.

## 🚀 Features

### Enhanced Vault Contract (`vault.clar`)
- **Secure Time Locking**: Lock STX until a specified block height
- **Owner Management**: Transfer ownership with two-step verification
- **Emergency Controls**: Emergency unlock capability for critical situations
- **Deposit Tracking**: Complete history of all deposits and withdrawals
- **Balance Management**: Real-time balance checking and validation
- **Enhanced Security**: Multiple error codes and validation checks

### Multi-Vault Manager (`multi-vault.clar`)
- **Multiple Vaults**: Create up to 50 individual time-locked vaults per user
- **Individual Management**: Each vault has its own unlock time and balance
- **Vault Lifecycle**: Create, fund, withdraw, and close vaults independently
- **User Dashboard**: Track all vaults owned by a user
- **Emergency Features**: Emergency withdrawal capabilities

## 🔧 Bug Fixes from Phase 1
1. **Fixed Deposit Function**: Now actually transfers STX to the contract
2. **Enhanced Withdraw Logic**: Proper balance checking and validation
3. **Error Handling**: Comprehensive error codes and assertions
4. **Security Improvements**: Multiple layers of validation

## 🛡️ Security Enhancements
- **Two-step ownership transfer**: Prevents accidental ownership loss
- **Emergency unlock system**: Owner can unlock in critical situations
- **Balance validation**: Prevents over-withdrawal attempts
- **Input validation**: All functions validate inputs thoroughly
- **Event tracking**: Complete audit trail of all operations

## 📋 Contract Functions

### Enhanced Vault Contract

#### Read-Only Functions
- `get-owner()` - Returns current contract owner
- `get-pending-owner()` - Returns pending owner (if any)
- `get-unlock-block()` - Returns unlock block height
- `get-balance()` - Returns contract STX balance
- `get-total-deposited()` - Returns total amount deposited
- `get-total-withdrawn()` - Returns total amount withdrawn
- `is-unlocked()` - Returns true if vault is unlocked
- `blocks-until-unlock()` - Returns blocks remaining until unlock
- `get-deposit(id)` - Returns deposit details by ID
- `get-withdrawal(id)` - Returns withdrawal details by ID

#### Public Functions
- `deposit(amount)` - Deposit STX to the vault
- `withdraw(amount, recipient)` - Withdraw STX (owner only, after unlock)
- `withdraw-all(recipient)` - Withdraw all available STX
- `set-unlock-block(block)` - Set new unlock block (owner only)
- `transfer-ownership(new-owner)` - Initiate ownership transfer
- `accept-ownership()` - Accept pending ownership
- `emergency-unlock()` - Enable emergency unlock
- `disable-emergency-unlock()` - Disable emergency unlock

### Multi-Vault Manager Contract

#### Read-Only Functions
- `get-vault(vault-id)` - Get vault details
- `get-user-vaults(user)` - Get all vault IDs for a user
- `get-vault-count()` - Get total number of vaults created
- `is-vault-unlocked(vault-id)` - Check if specific vault is unlocked

#### Public Functions
- `create-vault(unlock-block)` - Create a new time-locked vault
- `deposit-to-vault(vault-id, amount)` - Deposit to specific vault
- `withdraw-from-vault(vault-id, amount, recipient)` - Withdraw from specific vault
- `close-vault(vault-id)` - Close empty vault
- `emergency-withdraw-vault(vault-id, recipient)` - Emergency withdrawal

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks CLI tools

### Installation
```bash
# Clone the repository
git clone <your-repo-url>
cd time-locked-wallet

# Check contracts
clarinet check

# Run tests (create tests in tests/ directory)
clarinet test

# Deploy to testnet
clarinet deploy --testnet
```

### Basic Usage

#### Single Vault
```clarity
;; Deploy and deposit 1000 STX
(contract-call? .vault deposit u1000)

;; Set unlock block to 1000 blocks from now
(contract-call? .vault set-unlock-block (+ block-height u1000))

;; Check if unlocked
(contract-call? .vault is-unlocked)

;; Withdraw after unlock (owner only)
(contract-call? .vault withdraw u500 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

#### Multi-Vault
```clarity
;; Create a new vault
(contract-call? .multi-vault create-vault (+ block-height u500))

;; Deposit to vault ID 1
(contract-call? .multi-vault deposit-to-vault u1 u1000)

;; Check vault status
(contract-call? .multi-vault get-vault u1)

;; Withdraw after unlock
(contract-call? .multi-vault withdraw-from-vault u1 u500 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## 🧪 Testing

Create comprehensive tests in the `tests/` directory:

```bash
clarinet test tests/vault_test.ts
clarinet test tests/multi-vault_test.ts
```

## 📜 Error Codes

### Enhanced Vault
- `u401` - Not owner
- `u403` - Not unlocked
- `u404` - Insufficient balance
- `u405` - Invalid amount
- `u406` - Invalid block height
- `u407` - Emergency unlock active
- `u408` - Not pending owner

### Multi-Vault
- `u501` - Not vault owner
- `u502` - Vault not found
- `u503` - Vault locked
- `u504` - Invalid amount
- `u505` - Vault inactive
- `u506` - Maximum vaults reached

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## ⚠️ Disclaimer

This software is provided as-is. Always audit smart contracts before deploying to mainnet. The authors are not responsible for any loss of funds.

## 🔗 Resources

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://github.com/hirosystems/clarinet)
