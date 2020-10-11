require('dotenv-flow').config();

const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
    networks: {
        // Useful for testing. The `development` name is special - truffle uses it by default
        // if it's defined here and no other network is specified at the command line.
        // You should run a client (like ganache-cli, geth or parity) in a separate terminal
        // tab if you use this network and you must also set the `host`, `port` and `network_id`
        // options below to some value.
        //
        development: {
            host: "127.0.0.1",     // Localhost (default: none)
            port: 8545,            // Standard Ethereum port (default: none)
            network_id: "*",       // Any network (default: none)
        },

        //$ truffle migrate --network mainnet
        mainnet: {
            network_id: '1',
            provider: () => new HDWalletProvider(
                [process.env.DEPLOYER_PRIVATE_KEY],
                process.env.INFURA_MAINNET_API,
                0,
                1,
            ),
            gasPrice: 150000000000, // 150 gwei
            gas: 8000000,
            from: process.env.DEPLOYER_ACCOUNT,
            timeoutBlocks: 800,
        },

        //$ truffle migrate --network rinkeby
        rinkeby: {
            provider: () => new HDWalletProvider(
                [process.env.DEPLOYER_PRIVATE_KEY],
                process.env.INFURA_RINKEBY_API,
                0,
                1,
            ),
            network_id: 4,
            from: process.env.DEPLOYER_ACCOUNT,
            gasPrice: 50000000000,
            gas: 8000000,
            timeoutBlocks: 500,
        }
    },

    // Configure your compilers
    compilers: {
        solc: {
            version: '0.6.12',
            docker: false,
            parser: 'solcjs',
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 50000
                },
                evmVersion: 'istanbul',
            },
        },
    },
    plugins: [
        'truffle-plugin-verify'
    ]
};
