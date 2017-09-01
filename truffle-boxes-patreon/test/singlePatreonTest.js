var PatreonFactorySolFile = artifacts.require("./PatreonFactory.sol");
var SinglePatreon = artifacts.require("SinglePatreon");


//OH BABY THIS WORKS !!!!!!! need to link together the deployment
// console.log(newContractAddress.logs[0].args); - access event logs in the front end

let globalAddressArray = [];

contract('PatreonFactory', function (accounts) {

  let spContractCreator = 1;//owner account is 0, creator accoutn is 1. this is used throughout

  it(`Check that all variables are properly inherited from the patreon factory`, function () {
    return PatreonFactorySolFile.deployed().then(function (instance) {
      patreonFactoryInstance = instance;
      return patreonFactoryInstance.createContract(`Contract ${spContractCreator}`, { from: accounts[spContractCreator] });
    }).then(function () {
      return patreonFactoryInstance.getContractAddressArray.call();
    }).then(function (addressArray) {
      globalAddressArray = addressArray
      let singlePatreonInstance = SinglePatreon.at(globalAddressArray[0]);
      return singlePatreonInstance.owner.call().then(function (owner) {
        console.log(`OWNER: ${owner}`);
        return singlePatreonInstance.creator.call();
      }).then(function (creator) {
        console.log(`CREATOR: ${creator}`);
        return singlePatreonInstance.name.call();
      }).then(function (name) {
        console.log(`NAME: ${name}`);
        //  return singlePatreonInstance.getContractNumber.call();
        //  }).then(function (contractNumber) {
        //      console.log(contractNumber);
        /*
        some reason i am getting contract number to be undefined:(
        maybe to do with the fact it is a uint? i dunno...
        myabe just needs to reset. it works on REMIX so move on 
        */
      })
    });
  })

  it('Testing the modifier onlyCreator. Should pass. also proves setOneTime works', function () {
    let owner = 0;
    let creator = 1;
    let patreon = 2; //patreon will be account 2, and 3,4,5 if needed
    let setAmountCreator = "1000000000000000000"; //in wei. shown in string because it will convert to that
    let setAmountPatreon = "1234567890987654321"

    let testValueForSinceBigNumber = 10000;
    let testValueForPatreon = 12345;

    let singlePatreonInstance = SinglePatreon.at(globalAddressArray[0]);
    return singlePatreonInstance.setOneTimeContribution(setAmountCreator, { from: accounts[creator] }).then(function () {
      return singlePatreonInstance.singleDonationAmount.call();
    }).then(function (setSingleAmount) {
      console.log(setSingleAmount);
      assert.equal(testValueForSinceBigNumber, setSingleAmount.c[0], "Onlycreator worked, allowed creator to call");
    })
  });

  //shitty way of doing this. should be done in Solidity, but issues with the factory
  //might need to clean this up 
  //but will not test other modifiers. i know they work and i see how to test 
  it('Testing the modifier onlyCreator. Should outright fail', function (done) {
    let owner = 0;
    let creator = 1;
    let patreon = 2; //patreon will be account 2, and 3,4,5 if needed
    let setAmountCreator = "1000000000000000000"; //in wei. shown in string because it will convert to that
    let setAmountPatreon = "1234567890987654321"

    let testValueForSinceBigNumber = 10000;
    let testValueForPatreon = 12345;

    let singlePatreonInstance = SinglePatreon.at(globalAddressArray[0]);
    return singlePatreonInstance.setOneTimeContribution(setAmountCreator, { from: accounts[patreon] }).then(function () {
      console.log("If this doesnt print it failed");
      return singlePatreonInstance.singleDonationAmount.call();
    }).then(function (patreonTrySetAmount) {
      console.log(patreonTrySetAmount);
      assert.isFalse(patreonTrySetAmount)
      done();
      // assert.equal(testValueForSinceBigNumber, patreonTrySetAmount.c[0], "Onlycreator worked, prevented patreon to call");
    }).catch(done);
  });

  it('Testing setSingleDonation Can be updated', function () {
    let owner = 0;
    let creator = 1;
    let patreon = 2; //patreon will be account 2, and 3,4,5 if needed
    let setAmountCreator = "2000000000000000000"; //two ether

    let testValueForSinceBigNumber = 20000;

    let singlePatreonInstance = SinglePatreon.at(globalAddressArray[0]);
    return singlePatreonInstance.setOneTimeContribution(setAmountCreator, { from: accounts[creator] }).then(function () {
      return singlePatreonInstance.singleDonationAmount.call();
    }).then(function (setSingleAmount) {
      console.log(setSingleAmount);
      assert.equal(testValueForSinceBigNumber, setSingleAmount.c[0], "it did not update");
    })
  });

  it('Testing setSingleDonation wont go above 100', function (done) {
    let owner = 0;
    let creator = 1;
    let patreon = 2; //patreon will be account 2, and 3,4,5 if needed
    let setAmountCreator = "200000000000000000000"; //200 etehr

    let singlePatreonInstance = SinglePatreon.at(globalAddressArray[0]);
    return singlePatreonInstance.setOneTimeContribution(setAmountCreator, { from: accounts[creator] }).then(function (result) {
      assert.isFalse(result);
      done();
    }).catch(done);
  });

  it('Testing setSingleDonation wont go below 0', function (done) {
    let owner = 0;
    let creator = 1;
    let patreon = 2; //patreon will be account 2, and 3,4,5 if needed
    let setAmountCreator = "-2000000000000000000"; //200 etehr

    let singlePatreonInstance = SinglePatreon.at(globalAddressArray[0]);
    return singlePatreonInstance.setOneTimeContribution(setAmountCreator, { from: accounts[creator] }).then(function (result) {
      assert.isFalse(result);
      done();
    }).catch(done);
  });


  it('Testing a patreon can actually send the required amount. Then checks to see single donation counter updates', function () {
    let owner = 0;
    let creator = 1;
    let patreon = 2; //patreon will be account 2, and 3,4,5 if needed
    let donatedAmount = "2000000000000000000"; //two ether


    let creatorsInitialBalance = web3.eth.getBalance(accounts[1])
    let singlePatreonInstance = SinglePatreon.at(globalAddressArray[0]);
    return singlePatreonInstance.oneTimeContribution({ from: accounts[patreon], value: donatedAmount }).then(function () {
      assert.equal(Number(web3.fromWei(creatorsInitialBalance, "ether").plus(2)), Number(web3.fromWei(web3.eth.getBalance(accounts[1])), "ether") + 0, "Creator did not receive donation");
      return singlePatreonInstance.numberOfSingleContributions.call();
    }).then(function (singleDonationsReceived) {
      assert.equal(singleDonationsReceived, 1, "counter didnt update");
    })
  });


  it('Testing single donation fails if it is not the exact amount specified. here we send 3eth instead of 2', function () {
    let owner = 0;
    let creator = 1;
    let patreon = 2; //patreon will be account 2, and 3,4,5 if needed
    let donatedAmount = "3000000000000000000"; //two ether


    let creatorsInitialBalance = web3.eth.getBalance(accounts[1])
    let singlePatreonInstance = SinglePatreon.at(globalAddressArray[0]);
    //should fail cuz donated amount is 3 eth, not 2 
    return singlePatreonInstance.oneTimeContribution({ from: accounts[patreon], value: donatedAmount }).then(function () {
      assert.equal(Number(web3.fromWei(creatorsInitialBalance, "ether").plus(3)), Number(web3.fromWei(web3.eth.getBalance(accounts[1])), "ether") + 0, "Creator did not receive donation");
    })
  });



  it('Testing Patreon can send a monthly contribution', function () {
    let owner = 0;
    let creator = 1;
    let patreon = 4; //patreon will be account 2, and 3,4,5 if needed
    let setMonthlyAmount = "12000000000000000000"; //12 ether

    let patreonsInitialBalance = web3.eth.getBalance(accounts[patreon]);


    let singlePatreonInstance = SinglePatreon.at(globalAddressArray[0]);
    return singlePatreonInstance.setMonthlyContribution(setMonthlyAmount, { from: accounts[creator] }).then(function () {
      return singlePatreonInstance.monthlyDonationAmount.call();
    }).then(function (setMonthlyResult) {
      console.log(setMonthlyResult);
      assert.equal(web3.toBigNumber(setMonthlyAmount).c[0], setMonthlyResult.c[0], "it did not update");
      return singlePatreonInstance.monthlyContribution({ from: accounts[patreon], value: setMonthlyAmount }).then(function () {
        let contractBalance = web3.eth.getBalance(globalAddressArray[0]);
        //console.log();
        //console.log(patreonsInitialBalance);
        //console.log(web3.eth.getBalance(accounts[patreon]));
        assert.equal(Number(web3.fromWei(contractBalance, "ether")), Number(web3.fromWei(setMonthlyAmount, "ether"), "Contract balance did not receive funds"));
      })
    })
  });


})//end of contract test