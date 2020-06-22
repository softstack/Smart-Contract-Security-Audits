# Sca2t (Smart Contract Audit Assistant Tool): A set of utilities for auditing Solidity contracts.

#### 

Sca2t is an assistant tool for smart contract audit. It provides an output to visualize dependencies among smart contracts and generate event declaration and its call for debug to trace which functions are called.

Sca2t pronunciation is like skˈɚːt.

## Getting Started

Install it via npm:

```shell
npm install -g sca2t
```

## Command List

### eventgen

The `eventgen` command inserts event decalaration and its call into all of the contracts and functions except view functions.
Don't forget to backup your solidity files before do this.

```shell
sca2t eventgen *.sol
```
or

```shell
find . -name "*.sol" | xargs sca2t eventgen
```


### dependencies

The `dependencies` command outputs a draggable report to visualize dependencies among contracts.
Sca2t supports dependencies of inheritance, using declaration, and user defined type.
Sca2t search local or global package for contracts
If you want to search local, run the command on your package root, otherwise this searches global ones.

```shell
sca2t dependencies contracts/TGCrowdsale.sol
```

<img src="https://raw.githubusercontent.com/wiki/tagomaru/sca2t/images/dependencies.png" height="236">

### truffletogeth

The `truffletogeth` command outputs variable definition for geth console from json file which truffle generates during building contract. You may want to use this when you operate contract on geth console after deploying contract on truffle.
You can operate contract through variable name which you set after pasting the output on geth console.

```shell
sca2t truffletogeth TGCrowdsale "'0xb3a46f71ffcc2b4d3f0d45efa75bec24c96ac84f'" build/contracts/TGCrowdsale.json
```
<span style="color:red">* Address should be surrounded with double quotes and single quotes<span>

## License

GPL-3.0

