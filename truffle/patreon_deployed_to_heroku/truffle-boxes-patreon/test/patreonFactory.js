var PatreonFactorySolFile = artifacts.require("./PatreonFactory.sol");
var SinglePatreon = artifacts.require("SinglePatreon");

//this is grabbed from patreonFactory, and made a global variable, so SinglePatreon can be played with
let lastDeployedContractAddress = [];

//contract here provides a list of accounts. this is internal to truffle
contract('PatreonFactory', function (accounts) {

  //decide how many times you want to run the test
  let numberOfTests = 3;

  //this function creates 10 differernt patreon factories
  //the consolelog is explored to see that state is properly getting filled. omly on last test, as array will be full
  function loop10Creations(i) {
    it(`Contract creator is correctly stored for #${i} contract. Creator is ${accounts[i]}`, function () {
      return PatreonFactorySolFile.deployed().then(function (instance) {
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
          lastDeployedContractAddress = addressArray[i]; //always grab last contract
        }
        return patreonFactoryInstance.getOriginalCreatorArray.call();
      }).then(function (creatorArray) {
        if (i == numberOfTests) console.log(creatorArray);
      });
    });
  }
  for (let i = 0; i <= numberOfTests; i++) {
    loop10Creations(i);
  }
});




/*

//This must not work because it is seperated from the instance or something. the other way works,
//where i did it completly linked to the other one  

contract("SinglePatreon", function (accounts) {
  //test constructor
  it(`We check the last contract created to ensure owner, creator, and name global variables are saved properly`, function () {
    console.log(`HIHIH ${lastDeployedContractAddress}`)
    let singlePatreonInstance = SinglePatreon.at(lastDeployedContractAddress);
    return singlePatreonInstance.creator.call().then(function (creator) {
      console.log(creator);
      return singlePatreonInstance.name.call().then(function (name) {
        console.log(name);
      })
    });
  });
});

*/