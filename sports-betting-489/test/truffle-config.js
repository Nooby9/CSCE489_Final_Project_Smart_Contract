const HDWalletProvider = require('@truffle/hdwallet-provider');
const mnemonic = 'fringe kidney cushion breeze effort scene sugar tower trust cram paddle lake'


module.exports = {
  compilers: {

    solc: {

    version: "0.8.12"

    }

  },
 	networks: {
       	 development: {
      		host: "127.0.0.1", // The RPC server URL of your local Ganache instance
      		port: 7545,        // The port number used by Ganache
      		network_id: "5777"   // Match any network ID
    }
    // Other network configurations (e.g., goerli, mainnet) can be added here
  }
  
};
