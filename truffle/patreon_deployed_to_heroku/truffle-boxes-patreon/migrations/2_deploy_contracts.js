var PatreonFactory = artifacts.require("./PatreonFactory.sol");

module.exports = function(deployer) {
  deployer.deploy(PatreonFactory);
};
