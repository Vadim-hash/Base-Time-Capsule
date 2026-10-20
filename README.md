# Aether Time Capsule

A decentralized, time-locked vault protocol deployed on the Base L2 network. This smart contract allows users to securely lock digital assets or encoded messages, guaranteeing they remain inaccessible until a strict, user-defined future timestamp is reached.

## Core Features
* **Immutable Time-Locks:** Utilizes strict `block.timestamp` constraints to cryptographically enforce unlock conditions, preventing premature access.
* **Multi-Asset Support:** Engineered to handle native ETH deposits with minimal gas overhead during the locking phase.
* **On-Chain Inheritance:** Serves as a foundational layer for decentralized inheritance or long-term treasury vesting.

## Architecture & Security
Built using Solidity `0.8.37`. The protocol strictly adheres to the Checks-Effects-Interactions pattern to eliminate reentrancy attack vectors during the asset withdrawal execution.
