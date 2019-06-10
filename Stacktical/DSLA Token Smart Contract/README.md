# About Stacktical

Stacktical is a french software company specialized in applying predictive and blockchain technologies to performance, employee and customer management practices.

Stacktical.com is a comprehensive service level management platform that enables web service providers to automatically indemnify consumers for application performance failures, and reward employees that consistently meet service level objectives.

# DSLA Token Sale

This repository contains the following:
- DSLA tokens smart contract
![My image](https://github.com/Stacktical/stacktical-token-sales/blob/surya-graph/contracts/DSLA/Token-describe.png)
- DSLA Sale smart contract
![My image](https://github.com/Stacktical/stacktical-token-sales/blob/surya-graph/contracts/Crowdsale/Sale-describe.png)
- Unit tests
- Deployment files

## Consensys Surya Inheritance

![My image](https://github.com/Stacktical/stacktical-token-sales/blob/surya-graph/contracts/Crowdsale/DSLACrowdsale.png)
![My image](https://github.com/Stacktical/stacktical-token-sales/blob/surya-graph/contracts/DSLA/DSLA.png)

## Consensys Surya Graph

![My image](https://github.com/Stacktical/stacktical-token-sales/blob/surya-graph/MyContract.png)

## Setting up

### To Test the smart contract locally

## Requirement:

```
node >= 10.6.0
truffle
```
1/ After the `git clone`, please `npm install` to install all required packages.

*At this stage you can test the Smart Contrats in your local environment*

### To Deploy the smart contract on Testnet & Mainnet

If you don't have an Infura account yet, please go to infura.io and get an access token.

2/ Set your environment variables acordingly:

```
export DSLA_INFURA_APIKEY_DEV=<your Infura API Key> \  # <== Your access token from Infura in TESTNET
export DSLA_INFURA_APIKEY_PROD=<your Infura API Key> \  # <== Your access token from Infura in MAINNET
export DSLA_MNEMONIC_DEV="<your dev mnemonic>" \  #  <== The 12 mnemonic words of the account which will deploy the smart contracts in TESTNET
export DSLA_MNEMONIC_PROD="<your PRODUCTION mnemonic>;"  # The 12 mnemonic words of the account which will deploy the smart contracts in MAINNET
```

3/ Set the Smart contract parameters:

* Parameters of the smart contracts can be changed in `migrations/2_deploy_contracts.js`

Careful: Since the account will be deploying the smart contracts, it will also be the owner by default. This can be updated later thanks to the `Ownable` contract (to be found in the OpenZeppelin library).

## Run the Tests

### Locally

Please run `testrpc` in one console and `truffle test` to see the tests.

### Testnet & Mainnet

Please run `truffle migrate --network ropsten` to migrate the smart contracts in the Ropsen TestNet.

### MainNet

Please run `truffle migrate --network mainnet` to migrate the smart contracts on the MainNet.

**WARNING**: if there is change of contract for the ICO - before the end of the lock-up period - do not forget to edit the ICO address accordingly with the function `setCrowdsaleAddress()` from the deployed token, with the address of the ICO as an argument.

To interact with the contracts, every function has been documented with natspecs norm and therefore thoroughly described.

## Solidity code style

The [Solium](https://github.com/duaraghav8/Solium/) linter is used for linting and specifies the leading rules we follow for code styling, after that comes the [solidity style guide](https://solidity.readthedocs.io/en/v0.4.24/style-guide.html).

**Using solium linter**

*Installing*
```
npm install -g solium
solium -V
```

*Usage*
```
solium -f foobar.sol
solium -d contracts/

```

**functions should be grouped according to their visibility and ordered:**

* constructor
* fallback function (if exists)
* external
* public
* internal
* private

Within a grouping, place the `view` and `pure` functions last.
