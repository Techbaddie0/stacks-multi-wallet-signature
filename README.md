# Stacks Multi-Signature Wallet Contract

## Overview
This is a Stacks Multi-Signature Wallet contract designed for the Stacks Blockchain. It allows multiple wallet owners to collectively manage and secure funds, leveraging the robust security and scalability of the Stacks ecosystem. The contract provides features such as multi-signature transactions, daily spending limits, and timelocked withdrawals to ensure flexible yet secure fund management.

## Key Features

### Multi-Signature Transactions
Transactions require a predefined number of signatures (threshold) from wallet owners for execution.

### Daily Spending Limits
Individual spending caps can be set for each owner to control daily expenditures.

### Timelocked Withdrawals
Funds can be locked until a specific block height, adding an additional layer of control for future transactions.

### Dynamic Ownership Management
Owners can be added or removed, with safeguards to ensure wallet integrity.

### Transparent Wallet Information
Read-only functions provide visibility into wallet configurations, transactions, and limits.

## Prerequisites

### Stacks Blockchain
This contract is designed for deployment and execution on the Stacks Blockchain.

### Clarity Language
The contract is written in Clarity, a decidable smart contract language for Stacks.

## Deployment Instructions

### Set Up Environment
1. Install the necessary tools to interact with the Stacks network (e.g., Clarinet).
2. Connect to a Stacks node (testnet or mainnet).

### Deploy Contract
1. Compile and deploy the contract using your preferred toolchain.
2. Ensure the contract owner (deployer) is properly set.

## Key Constants and Data Variables

- `ERR-NOT-OWNER`: Error returned if a non-owner attempts restricted actions.
- `ERR-INVALID-TX`: Error for invalid transaction access.
- `ERR-NOT-ENOUGH-SIGS`: Error when the required number of signatures isn't met.
- `ERR-WALLET-ALREADY-INITIALIZED`: Prevents double initialization.
- `ERR-CANNOT-REMOVE-OWNER`: Error to protect critical owner operations.
- `contract-owner`: The account that deployed the contract.

### Data Variables
- `threshold`: Minimum number of signatures required to approve a transaction.
- `owners`: List of current wallet owners.
- `tx-count`: Counter for tracking transactions.
- `daily-spending-limits`: Spending caps for each owner.
- `daily-spending-tracker`: Tracks daily expenditures per owner.
- `transactions`: Stores transaction details.
- `timelock-withdrawals`: Stores timelocked withdrawal requests.
- `current-block-height`: Mock variable for block height management.

## Public Functions

1. **initialize-wallet**
    - Initializes the wallet with a set of owners and a signature threshold.
    - **Parameters:**
      - `wallet-owners`: List of wallet owners.
      - `sig-threshold`: Minimum number of signatures required.

2. **propose-transaction**
    - Proposes a new transaction requiring approval by other owners.
    - **Parameters:**
      - `recipient`: Address to receive the funds.
      - `amount`: Amount of STX to transfer.

3. **sign-transaction**
    - Allows an owner to sign a proposed transaction.
    - **Parameters:**
      - `tx-id`: ID of the transaction to sign.

4. **execute-transaction**
    - Executes a transaction once the required number of signatures is obtained.
    - **Parameters:**
      - `tx-id`: ID of the transaction to execute.

5. **set-daily-spending-limit**
    - Sets a daily spending limit for a specific owner.
    - **Parameters:**
      - `owner`: Principal of the owner.
      - `limit`: Daily spending cap in STX.

6. **create-timelocked-withdrawal**
    - Creates a withdrawal locked until a specific block height.
    - **Parameters:**
      - `recipient`: Address to receive the funds.
      - `amount`: Amount of STX to withdraw.
      - `lock-period`: Number of blocks to lock the withdrawal.

7. **approve-timelocked-withdrawal**
    - Approves a timelocked withdrawal.
    - **Parameters:**
      - `tx-id`: ID of the timelocked withdrawal.

8. **execute-timelocked-withdrawal**
    - Executes an approved timelocked withdrawal once the lock period has passed.
    - **Parameters:**
      - `tx-id`: ID of the timelocked withdrawal.

## Read-Only Functions

1. **get-transaction**
    - Retrieves the details of a specific transaction by its ID.

2. **get-wallet-owners**
    - Returns the list of current wallet owners.

3. **get-signature-threshold**
    - Returns the number of signatures required for transaction execution.

4. **is-wallet-owner**
    - Checks if a given account is a wallet owner.

5. **get-daily-spending-limit**
    - Returns the daily spending limit for a specific owner.

6. **get-timelocked-withdrawal**
    - Retrieves the details of a timelocked withdrawal by its ID.

## Security Considerations

### Owner Validation
Only owners can propose, sign, or execute transactions.

### Signature Threshold
Transactions are executed only when the required number of owner approvals is met.

### Daily Limits
Spending limits ensure controlled and secure fund usage.

### Timelocks
Prevent premature withdrawals and ensure funds are locked for future use.

## Usage Examples

### Initialize Wallet
```clarity
(begin
  (initialize-wallet (list tx-sender another-owner) u2)
)
```

### Propose and Execute Transaction
```clarity
(propose-transaction some-recipient u1000)
(sign-transaction u0)
(execute-transaction u0)
```

### Set Daily Spending Limit
```clarity
(set-daily-spending-limit owner-principal u500)
```

## Conclusion
This contract provides a comprehensive, secure, and flexible system for managing shared funds on the Stacks Blockchain. It leverages multi-signature approval and advanced features like timelocks to ensure optimal security for all wallet activities.