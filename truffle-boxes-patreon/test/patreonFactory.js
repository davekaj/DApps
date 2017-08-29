var PatreonFactory = artifacts.require("./PatreonFactory.sol");

//this is grabbed from patreonFactory, and made a global variable, so SinglePatreon can be played with
let firstDeployedContractAddress; 


//contract here provides a list of accounts. this is internal to truffle
contract('PatreonFactory', function (accounts) {

  //decide how many times you want to run the test
  let numberOfTests = 10;

  //this function creates 10 differernt patreon factories
  //the consolelog is explored to see that state is properly getting filled. omly on last test, as array will be full
  function loop10Creations(i) {
    it(`Contract creator is correctly stored for #${i} contract. Creator is ${accounts[i]}`, function (done) {
      return PatreonFactory.deployed().then(function (instance) {
        patreonFactoryInstance = instance;
        return patreonFactoryInstance.createContract(`Contract ${i}`, { from: accounts[i] });
      }).then(function () {
        return patreonFactoryInstance.getOriginalCreator.call(0);
      }).then(function (creator) {
        assert.equal(creator, accounts[0], "The contract wasn't created");
        return patreonFactoryInstance.getNameArray.call();
      }).then(function (nameArray) {
        if (i == numberOfTests) console.log(nameArray)
        return patreonFactoryInstance.getContractAddressArray.call();
      }).then(function (addressArray) {
        if (i == numberOfTests) {
          console.log(addressArray);
          firstDeployedContractAddress = addressArray[i]; //always grab last contract
        }
        return patreonFactoryInstance.getOriginalCreatorArray.call();
      }).then(function (creatorArray) {
        if (i == numberOfTests) console.log(creatorArray);
      });
      done();
    });
  }
  for (let i = 0; i <= numberOfTests; i++) {
    loop10Creations(i);
  }
});


contract("SinglePatreon", function(accounts){

//test constructor


});