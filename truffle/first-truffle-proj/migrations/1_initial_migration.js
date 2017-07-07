var Migrations = artifacts.require("./Migrations.sol"); //tell truffle which contracts we'd like to interact with. similar to require()
  //does not have to match the filename as seen above. can just match the contract within the file

module.exports = function(deployer) {
  deployer.deploy(Migrations);
};

//these help you delpoy contractions to the ethereum network
//stage deployment tasks, and they're written under the assumption that your deployment needs will change over time
//  $truffle migrate runs all migrations within your projects migrations directory
//**** AT ITS SIMPLEST, MIGRATIONS ARE SIMPLY A SET OF MANAGED DEPLOYMENT SCRIPTS. LOOK ABOVE, CAN SEE CLEARLY */

//you can use --reset to run all of your migrations from the beginning