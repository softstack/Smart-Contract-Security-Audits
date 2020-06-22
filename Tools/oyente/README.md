Oyente
======

An Analysis Tool for Smart Contracts

[![Gitter][gitter-badge]][gitter-url]
[![License: GPL v3][license-badge]][license-badge-url]
[![Build Status](https://travis-ci.org/melonproject/oyente.svg?branch=master)](https://travis-ci.org/melonproject/oyente)

*This repository is currently maintained by Xiao Liang Yu ([@yxliang01](https://github.com/yxliang01)). If you encounter any bugs or usage issues, please feel free to create an issue on [our issue tracker](https://github.com/melonproject/oyente/issues).*

## Quick Start

Oyente tool requires the following dependencies:

There are two methods for this, both methods need the following commands to be run
If you haven’t installed python in your system, run the following commands

```
sudo apt install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt-get install python3
```

Install z3. For this, download the file from this link here.
Extract files, move into the directory and run the following commands (this gonna take a while more than you expect):

```
wget https://github.com/Z3Prover/z3/archive/z3-4.5.0.tar.gz
tar xvzf z3-4.5.0.tar.gz
```

```
python scripts/mk_make.py -python
cd build
make
sudo make install
```
You need to install this library,
```
sudo apt-get install libz3-dev
```

## Installing the Oyente tool:
For this you need to install pip
```
sudo apt install python3-pip
```

Exectute the following commands:

```
sudo apt-get install solc
sudo apt-get install evm
pip3 install web3==3.7.0
pip3 install oyente
```

The above command fails and returns an error in most of the cases, if it works you can use by running the below commands:

```
oyente -s <contract name>

```
Dependencies:

The following require a Linux system to fufill. macOS instructions forthcoming.

[solc](https://github.com/melonproject/oyente#solc)
[evm](https://github.com/melonproject/oyente#evm-from-go-ethereum)

### Evaluating Ethereum Contracts

```
#evaluate a local solidity contract
python oyente.py -s <contract filename>

#evaluate a local solidity with option -a to verify assertions in the contract
python oyente.py -a -s <contract filename>

#evaluate a local evm contract
python oyente.py -s <contract filename> -b

#evaluate a remote contract
python oyente.py -ru https://gist.githubusercontent.com/loiluu/d0eb34d473e421df12b38c12a7423a61/raw/2415b3fb782f5d286777e0bcebc57812ce3786da/puzzle.sol

```

And that's it! Run ```python oyente.py --help``` for a list of options.

## Paper

The accompanying paper explaining the bugs detected by the tool can be found [here](https://www.comp.nus.edu.sg/~prateeks/papers/Oyente.pdf).

## Miscellaneous Utilities

A collection of the utilities that were developed for the paper are in `misc_utils`. Use them at your own risk - they have mostly been disposable.

1. `generate-graphs.py` - Contains a number of functions to get statistics from contracts.
2. `get_source.py` - The *get_contract_code* function can be used to retrieve contract source from [EtherScan](https://etherscan.io)
3. `transaction_scrape.py` - Contains functions to retrieve up-to-date transaction information for a particular contract.

## Benchmarks

Note: This is an improved version of the tool used for the paper. Benchmarks are not for direct comparison.

To run the benchmarks, it is best to use the docker container as it includes the blockchain snapshot necessary.
In the container, run `batch_run.py` after activating the virtualenv. Results are in `results.json` once the benchmark completes.

The benchmarks take a long time and a *lot* of RAM in any but the largest of clusters, beware.

Some analytics regarding the number of contracts tested, number of contracts analysed etc. is collected when running this benchmark.

## Contributing

Checkout out our [contribution guide](https://github.com/melonproject/oyente/blob/master/CONTRIBUTING.md) and the code structure [here](https://github.com/melonproject/oyente/blob/master/code.md).


[gitter-badge]: https://img.shields.io/gitter/room/melonproject/oyente.js.svg?style=flat-square
[gitter-url]: https://gitter.im/melonproject/oyente?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge
[license-badge]: https://img.shields.io/badge/License-GPL%20v3-blue.svg?style=flat-square
[license-badge-url]: ./LICENSE
