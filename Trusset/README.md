# Trusset Security Audit by Softstack

## Overview

Softstack completed a security audit for Trusset, a regulated tokenization platform focused on real world asset infrastructure.

The review covered four interconnected codebases and focused on the interaction between compliance, credit, custody, and upgrade governance.

## What Trusset Does

Trusset provides infrastructure for regulated tokenized assets.

The system has to ensure that:

| Area       | Requirement                             |
| ---------- | --------------------------------------- |
| Transfers  | Compliance rules are respected          |
| Credit     | Collateral requirements are enforced    |
| Custody    | User balances remain accurate           |
| Governance | Upgrades and permissions are controlled |

## Audit Focus

Softstack reviewed the system across several critical areas:

| Area                    | Review Focus                      |
| ----------------------- | --------------------------------- |
| Identity registry       | Compliance and permission logic   |
| Lending flows           | Collateral and credit behavior    |
| Custody flows           | Balance safety and fund routing   |
| Liquidation logic       | Correct routing and execution     |
| Upgrade governance      | System control and upgrade safety |
| Cross codebase behavior | Risks between connected modules   |

## Key Security Relevance

The audit was especially important because Trusset’s architecture connects multiple sensitive components.

Some issues only became visible when the four codebases were reviewed together, rather than as isolated systems.

This included boundary risks around accounting behavior, stock split handling, custody to lending callbacks, and fund routing.

## Audit Result

The audit reached a zero open issues state.

Ten high severity issues were identified and remediated by the Trusset engineering team.

## About Softstack

Softstack is a Web3 security firm specializing in smart contract audits, blockchain infrastructure reviews, tokenization systems, DeFi protocols, and institutional crypto applications.

