var PatreonFactorySolFile = artifacts.require("./PatreonFactory.sol");
var SinglePatreon = artifacts.require("SinglePatreon");


//OH BABY THIS WORKS !!!!!!! need to link together the deployment
// console.log(newContractAddress.logs[0].args); - access event logs in the front end

contract('PatreonFactory', function (accounts) {

  let i = 0;

  it(`Check that all variables are properly inherited from the patreon factory`, function () {
    return PatreonFactorySolFile.deployed().then(function (instance) {
      patreonFactoryInstance = instance;
      return patreonFactoryInstance.createContract(`Contract ${i}`, { from: accounts[i] });
    }).then(function () {
      return patreonFactoryInstance.getContractAddressArray.call();
    }).then(function (addressArray) {
      let singlePatreonInstance = SinglePatreon.at(addressArray[0]);
      return singlePatreonInstance.owner.call().then(function (owner) {
        console.log(owner);
        return singlePatreonInstance.creator.call();
      }).then(function (creator) {
        console.log(creator);
        return singlePatreonInstance.name.call();
      }).then(function (name) {
        console.log(name);
        return singlePatreonInstance.contractNumber.call();
      }).then(function (contractNumber) {
        console.log(contractNumber);
      })
    });
  })
});



