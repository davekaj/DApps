var PatreonFactory = artifacts.require("./PatreonFactory.sol");

contract('PatreonFactory', function(accounts) {


  
  it(`Contract creator is correctly ${accounts[0]}`, function() {
    return PatreonFactory.deployed().then(function(instance) {
      patreonFactoryInstance = instance;

      return patreonFactoryInstance.createContract("Contract 1", {from: accounts[0]});
    }).then(function() {
      return patreonFactoryInstance.getOriginalCreator.call(0);
    }).then(function(creator) {
      assert.equal(creator, accounts[0], "The contract wasn't created");
    });
  });







});
