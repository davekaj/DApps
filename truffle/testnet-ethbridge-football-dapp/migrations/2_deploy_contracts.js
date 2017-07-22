var usingOraclize = artifacts.require("./usingOraclize.sol");
var WolframAlpha = artifacts.require("./WolframAlpha.sol");

module.exports = function(deployer) {
  deployer.deploy(usingOraclize);
  deployer.link(usingOraclize, WolframAlpha);
  deployer.deploy(WolframAlpha);
};
