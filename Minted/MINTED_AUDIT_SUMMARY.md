# Minted — Canton Network Protocol Security Audit

**Auditor:** softstack  
**Customer:** MintedAssociates Corp
**Scope:** Core Contracts (Canton Network / DAML)
**Audit period:** 15.02.2026 – 28.02.2026 (re-check 28.02.2026, deprecation re-issue 05.05.2026)
**Repository:** `[luthatdude/Minted-mUSD-Canton](https://github.com/luthatdude/Minted-mUSD-Canton)` @ commit `393fd96f322674b25dd4b0c21f593f0874b86211`

> This document is a public summary of the audit performed by softstack on the Minted Canton Network Protocol. Detailed vulnerability descriptions, exploit scenarios, code locations and remediation guidance are published on a later time.

---

## 1. About Minted

Minted is a stablecoin protocol built on the Canton Network. mUSD is minted 1:1 against USDC, with Canton serving as the institutional-grade accounting, compliance and settlement layer. The audited DAML templates implement the protocol's privacy-enabled distributed ledger layer, providing on-ledger minting, staking, lending, governance and compliance primitives.

## 2. Scope

The audit covered the following Canton Network DAML modules:


| Module                                     | Purpose                                                                                  |
| ------------------------------------------ | ---------------------------------------------------------------------------------------- |
| **CantonDirectMint**                       | 1:1 USDC-backed mUSD minting with rate limiting and compliance hooks                     |
| **CantonSMUSD**                            | Yield vault with share-price model and cooldown enforcement                              |
| **CantonLending**                          | Collateralized borrowing with escrow-based collateral, interest accrual and liquidation  |
| **CantonBoostPool**                        | Deposit caps, LP issuance, validator reward distribution and price sync                  |
| **CantonLoopStrategy**                     | Looped leverage strategy on top of the lending module                                    |
| **InterestRateService**                    | Market-data driven interest-rate parameters                                              |
| **Compliance**                             | Blacklist / freeze registry with O(log n) Set-based lookups                              |
| **Governance**                             | Multi-sig framework with proposal lifecycle, emergency rollback and upgrade coordination |
| **Upgrade**                                | Migration tickets, upgrade registry and rollback windows                                 |
| **MintedMUSD / V3 (InstitutionalAssetV4)** | Core mUSD token with MPA embedding, split / merge / transfer, observer privacy           |
| **UserPrivacySettings**                    | Per-user observer / privacy controls                                                     |


**Codebase metrics in scope:** 15 DAML source units, **7,054 total lines** (4,937 nSLOC), 213 instructions, 229 functions.

## 3. Audit Methodology

Two independent softstack experts performed an unbiased, isolated review. The methodology combined manual code review with automated tooling:

### Code review

- Review of specifications, sources and instructions provided by Minted to confirm size, scope and intended functionality.
- Manual line-by-line review of all in-scope DAML source code.
- Comparison of actual behaviour against the documented specification.

### Testing and automated analysis

- Test-coverage analysis to determine which code paths are exercised by the project's own DAML test scripts.
- Symbolic execution to determine which inputs reach which branches of each choice.
- Use of Canton / DAML linters and static analyzers to surface common authorization, signatory and key-uniqueness issues.

### Best-practices review

- Review against established DAML smart-contract patterns (signatory / observer disclosure, choice authorization, contract-key usage, archive semantics, monetary arithmetic).
- Review against industry recommendations for stablecoin, lending and governance protocols.

## 4. Results

### 4.1 Severity and resolution overview


| Severity      | Count  | Fixed  | Acknowledged |
| ------------- | ------ | ------ | ------------ |
| Critical      | 0      | 0      | 0            |
| **High**      | **5**  | **5**  | 0            |
| **Medium**    | **11** | **7**  | **4**        |
| **Low**       | **24** | **20** | **4**        |
| Informational | 0      | 0      | 0            |
| **Total**     | **40** | **32** | **8**        |


### 4.2 Outcome

> The Minted team has successfully addressed all identified issues from the audit. All vulnerabilities have been mitigated based on the recommendations provided in the report. A follow-up review confirms that the fixes have been implemented effectively, ensuring the security and functionality of the smart contract.

100 % of High-severity findings were fixed. The remaining 8 acknowledged items are Medium / Low severity issues whose residual risk Minted accepted and documented.

## 5. Findings index

Finding titles, descriptions, code locations, attack scenarios and remediation steps are available exclusively in the signed PDF report. Only the finding ID, severity and remediation status are reproduced below.

### High severity (5)


| ID   | Status |
| ---- | ------ |
| H-01 | FIXED  |
| H-02 | FIXED  |
| H-03 | FIXED  |
| H-04 | FIXED  |
| H-05 | FIXED  |


### Medium severity (11)


| ID   | Status       |
| ---- | ------------ |
| M-01 | ACKNOWLEDGED |
| M-02 | FIXED        |
| M-03 | FIXED        |
| M-04 | FIXED        |
| M-05 | FIXED        |
| M-06 | FIXED        |
| M-07 | ACKNOWLEDGED |
| M-08 | ACKNOWLEDGED |
| M-09 | ACKNOWLEDGED |
| M-10 | FIXED        |
| M-11 | FIXED        |


### Low severity (24)


| ID   | Status       |
| ---- | ------------ |
| L-01 | FIXED        |
| L-02 | FIXED        |
| L-03 | FIXED        |
| L-04 | FIXED        |
| L-05 | FIXED        |
| L-06 | FIXED        |
| L-07 | FIXED        |
| L-08 | FIXED        |
| L-09 | FIXED        |
| L-10 | FIXED        |
| L-11 | ACKNOWLEDGED |
| L-12 | FIXED        |
| L-13 | FIXED        |
| L-14 | ACKNOWLEDGED |
| L-15 | FIXED        |
| L-16 | FIXED        |
| L-17 | FIXED        |
| L-18 | FIXED        |
| L-19 | ACKNOWLEDGED |
| L-20 | FIXED        |
| L-21 | ACKNOWLEDGED |
| L-22 | FIXED        |
| L-23 | FIXED        |
| L-24 | FIXED        |


## 6. Verifying this report

The full PDF report is published alongside this summary. Its integrity can be verified against the SHA-256 hash above:

```bash
shasum -a 256 softstack_minted_core_contracts_security_audit_report_05052026.pdf
# expected:
# 5cf0d0c9585a9d5a6449f582aba5a8f0eac26ede505a3d2ff8bc54fe4b1568e8
```

The version history of the audit report is:


| Version | Date       | Description                                                    |
| ------- | ---------- | -------------------------------------------------------------- |
| 0.1     | 15.02.2026 | Layout                                                         |
| 0.5     | 20.02.2026 | Manual + Automated Security Testing                            |
| 1.0     | 28.02.2026 | Final document                                                 |
| 1.1     | 28.02.2026 | Re-check                                                       |
| 1.2     | 05.05.2026 | Bridge / Ethereum components deprecated and removed from scope |


## 7. About softstack GmbH

Established in 2017 (originally as Chainsulting, rebranded to softstack GmbH in 2023), softstack is a German cybersecurity firm specialising in smart-contract audits, penetration testing and security consulting. ISO 27001 certified, the firm has audited protocols safeguarding **over $100 billion** in user funds across Ethereum, Solana, Canton, Polygon, Tezos, TON and other major blockchain platforms.

- Website: [https://softstack.io](https://softstack.io)
- Contact: [hello@softstack.io](mailto:hello@softstack.io)

