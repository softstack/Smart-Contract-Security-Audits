require('dotenv').config()
const HDWalletProvider = require("truffle-hdwallet-provider");
const babelRegister = require('babel-register');
const babelPolyfill = require('babel-polyfill');

// Infura API key
const infura_apikey_dev = process.env.DSLA_INFURA_APIKEY_DEV;
const infura_apikey_prod = process.env.DSLA_INFURA_APIKEY_PROD;

// 12 mnemonic words that represents the account that will own the contract
const mnemonic_dev = process.env.DSLA_MNEMONIC_DEV;
const mnemonic_prod = process.env.DSLA_MNEMONIC_PROD;

module.exports = {
    networks: {
        development: {
            host: "localhost",
            port: 8545,
            network_id: "*" // Match any network id
        },
        ropsten: {
            provider: function() {
                return new HDWalletProvider(mnemonic_dev, "https://ropsten.infura.io/" + infura_apikey_dev);
            },
            network_id: "3",
            gas: 4612388
        },
        rinkeby: {
            provider: function() {
                return new HDWalletProvider(mnemonic_dev, "https://rinkeby.infura.io/" + infura_apikey_dev);
            },
            network_id: "2",
            gas: 4612388
        },
        mainnet: {
            provider: function() {
                return new HDWalletProvider(mnemonic_prod, "https://mainnet.infura.io/" + infura_apikey_prod);
            },
            network_id: "1",
            gas: 4612388
        }
    },
    rpc: {
        host: 'localhost',
        post:8080
    },
    solc: {
        optimizer: {
            enabled: true,
            runs: 200
        }
    }
};
