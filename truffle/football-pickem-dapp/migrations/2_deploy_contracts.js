var FootballContract = artifacts.require("./FootballPickemContract.sol");

module.exports = function(deployer) {
  deployer.deploy(FootballContract);
};
