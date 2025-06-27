# Time-Locked Wallet (Vault) – Stacks Blockchain

## Overview

This Clarity smart contract allows the contract owner to deposit STX and lock them until a specified block height. Withdrawals are restricted until that block is reached.

## Features
- Set block lock time.
- Deposit funds.
- Withdraw funds after unlock block.
- Only the owner can withdraw or change unlock settings.

## Usage

### Deploy
```bash
clarinet deploy
