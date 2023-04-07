var Betting = artifacts.require("bettingApp.sol");

module.exports = async function(deployer) {
 await deployer.deploy(Betting);
 const deployedContract = await Betting.deployed();
 console.log("address: ", deployedContract.address);
};
