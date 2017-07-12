var ConvertLib = artifacts.require("./ConvertLib.sol");
var DecypherCoin = artifacts.require("./DecypherCoin.sol");

module.exports = function(deployer) {
 // deployer.deploy(ConvertLib);
//  deployer.link(ConvertLib, DecypherCoin);
  deployer.deploy(DecypherCoin);
};
