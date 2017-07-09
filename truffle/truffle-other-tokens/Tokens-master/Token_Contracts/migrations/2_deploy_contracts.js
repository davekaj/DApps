var HST = artifacts.require("./HumanStandardToken.sol");
var HSTF = artifacts.require("./HumanStandardTokenFactory.sol");

module.exports = function(deployer) {
  deployer.deploy(HST);
 // deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(HSTF);
};


//i got this to work on my own, good very good