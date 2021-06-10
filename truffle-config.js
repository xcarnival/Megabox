var path = require("path");
var HDWalletProvider = require("truffle-hdwallet-provider");

const providerFactory = (network) => {
    require("dotenv").config({
        path: path.join(__dirname, `./.env.${network}`),
    });
    return new HDWalletProvider(
        process.env.MNEMONIC_PHRASE,
        process.env.NETWORK_ENDPOINT
    );
};

module.exports = {
    networks: {
        mainnet: {
            provider: () => providerFactory("mainnet"),
            network_id: 1,
            gas: 8000000, 
        },
        ropsten: {
            provider: () => providerFactory("ropsten"),
            network_id: 3,
            gas: 8000000,
        },
        rinkeby: {
            provider: () => providerFactory("rinkeby"),
            network_id: 4,
            gas: 8000000, 
        },
        bsctest: {
            provider: () => providerFactory("bsctest"),
            network_id: 97,
            gas: 8000000, 
            gasPrice: 10000000000
        },
        bscmain: {
            provider: () => providerFactory("bscmain"),
            network_id: 56,
            gas: 8000000, 
            gasPrice: 5000000000
        },
    },
    compilers: {
        solc: {
            version: "0.6.12",
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200,
                },
            },
        },
    },
};
