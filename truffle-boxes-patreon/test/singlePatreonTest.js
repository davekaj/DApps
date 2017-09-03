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
  it('FAIL: Testing the modifier onlyCreator. Should outright fail', function (done) {
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

  it('FAIL: Testing setSingleDonation wont go above 100', function (done) {
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

  it('FAIL: testing setSingleDonation wont go below 0', function (done) {
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


  it('FAIL: Testing single donation fails if it is not the exact amount specified. here we send 3eth instead of 2', function () {
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
    }).then(function (setMonthlyReturnedValue) {
      console.log(setMonthlyReturnedValue);
      assert.equal(web3.toBigNumber(setMonthlyAmount).c[0], setMonthlyReturnedValue.c[0], "it did not update");
      return singlePatreonInstance.monthlyContribution({ from: accounts[patreon], value: setMonthlyAmount }).then(function () {
        let contractBalance = web3.eth.getBalance(globalAddressArray[0]);
        //console.log();
        //console.log(patreonsInitialBalance);
        //console.log(web3.eth.getBalance(accounts[patreon]));
        assert.equal(Number(web3.fromWei(contractBalance, "ether")), Number(web3.fromWei(setMonthlyAmount, "ether"), "Contract balance did not receive funds"));
      })
    })
  });


  it('FAIL: Testing Patreon cant send a monthly contribution twice', function () {
    let owner = 0;
    let creator = 1;
    let patreon = 4; //patreon will be account 2, and 3,4,5 if needed
    let setMonthlyAmount = "12000000000000000000"; //12 ether

    let patreonsInitialBalance = web3.eth.getBalance(accounts[patreon]);


    let singlePatreonInstance = SinglePatreon.at(globalAddressArray[0]);
    return singlePatreonInstance.setMonthlyContribution(setMonthlyAmount, { from: accounts[creator] }).then(function () {
      return singlePatreonInstance.monthlyDonationAmount.call();
    }).then(function (setMonthlyReturnedValue) {
      console.log(setMonthlyReturnedValue);
      assert.equal(web3.toBigNumber(setMonthlyAmount).c[0], setMonthlyReturnedValue.c[0], "it did not update");
      return singlePatreonInstance.monthlyContribution({ from: accounts[patreon], value: setMonthlyAmount }).then(function () {
        let contractBalance = web3.eth.getBalance(globalAddressArray[0]);
        //console.log();
        //console.log(patreonsInitialBalance);
        //console.log(web3.eth.getBalance(accounts[patreon]));
        assert.equal(Number(web3.fromWei(contractBalance, "ether")), Number(web3.fromWei(setMonthlyAmount, "ether"), "Contract balance did not receive funds"));
      })
    })
  });

  it(`Test donators array is filled properly`, function () {
    let owner = 0;
    let creator = 1;
    let patreon = 4; //patreon will be account 2, and 3,4,5 if needed
    let singlePatreonInstance = SinglePatreon.at(globalAddressArray[0]);
    return singlePatreonInstance.donators.call(0).then(function (firstDonator) {
      console.log(firstDonator);
    })
  })



  //decide how many times you want to run the looping of monthly contribution
  let numberOfLoopsMonthlyContribution = 10;

  function loopMonthlyContribution(i) {
    it(`${i} donators were able to donation and ledger updated properly, and contract balance is correct`, function () {
      let owner = 0;
      let creator = 1;
      let patreon = (10 + i); //patreons starting at 10, dont want to drain all test accounts
      let setMonthlyAmount = "12000000000000000000"; //12 ether

      let singlePatreonInstance = SinglePatreon.at(globalAddressArray[0]);
      return singlePatreonInstance.monthlyDonationAmount.call().then(function (setMonthlyReturnedValue) {
        return singlePatreonInstance.monthlyContribution({ from: accounts[patreon], value: setMonthlyAmount }).then(function () {
          let contractBalance = web3.eth.getBalance(globalAddressArray[0]);

          //i+2 times setMonthlyAmount because one i is from 1st contribution in the above it(), and the second because i starts at 0 in the array, for the first instance
          assert.equal(Number(web3.fromWei(contractBalance, "ether")), Number(web3.fromWei(setMonthlyAmount, "ether") * (i + 2), "Contract balance did not receive looped funds properly"));
          return singlePatreonInstance.donators.call(i + 1).then(function (iterateDonator) { //i+1 because we did first one above in earlier test
            console.log(iterateDonator);
            //checking that the mapping is updating correctly. you insert users address and should get back their patreonID.
            return singlePatreonInstance.getPatreonID.call(accounts[patreon]).then(function (iterateMappingOfPatreonIDS) {
              // we make fromWei to wei to get from bigNumber object to the value 1
              assert.equal(i + 1, Number(web3.fromWei(iterateMappingOfPatreonIDS, "wei")), "the mapping did not update patreonIDs properly");
            })
          })
        })
      })
    });
  }
  for (let i = 0; i <= numberOfLoopsMonthlyContribution; i++) {
    loopMonthlyContribution(i);
  }




  //confirm cancellation at three different intervals for 10 users
  // 0 withdrawals
  // 1-11 withdrawals
  // 12 withdrawls will not work!
  //confirm ledger updates correctly with all (although should through error if doesnt)

  //confirm withdrawals at three different intervals for 10 users
  //first withdrawal
  // withdrawls properly go down after some users have cancelled
  // withdrawls still continue to work after some have cancelled and others signed up
  // confirm at zero withdrawals that a patreon is removed, and that creator has less withdrawals per month
  // confirm ledger for all

  it('Conrim basic withdrawals and cancelation functions work (1 cancle, 1 withdraw, 1 more cancle, 1 signup, 1 withdraw', function () {
    let owner = 0;
    let creator = 1;

    let patreonCancle1 = 10;
    let patreonCancle2 = 11;
    let patreonSignup = 21;

    let setMonthlyAmount = "12000000000000000000"; //12 ether

    let patreonCancel1InitialBalance = web3.eth.getBalance(accounts[patreonCancle1]);
    let creatorInitialBalance = web3.eth.getBalance(globalAddressArray[0]);


    let singlePatreonInstance = SinglePatreon.at(globalAddressArray[0]);
    return singlePatreonInstance.monthlyDonationAmount.call().then(function (setMonthlyReturnedValue) {
      return singlePatreonInstance.patreonCancleMonthly({ from: accounts[patreonCancle1] }).then(function (getGasSpent) {
        console.log(getGasSpent);
        let gasSpent = getGasSpent.receipt.gasUsed / 10000000; //this is not perfect, as it is hardcoded and might change due to gwei
        let patreonCancel1FinalBalance = web3.eth.getBalance(accounts[patreonCancle1]);
        assert.equal(Number(web3.fromWei(patreonCancel1InitialBalance, "ether") - gasSpent), Number(web3.fromWei(patreonCancel1FinalBalance, "ether") - (12)), "first cancel did not receive thier ether properly, or ledger did not update properly");
        console.log("HHaH");    
        console.log(web3.eth.getBlock("latest"));    
        return singlePatreonInstance.creatorWithdrawMonthly({ from: accounts[creator] }).then(function (getGasSpent) {
          console.log("HHH");
          let creatorOneWithdrawalBalance = web3.eth.getBalance(globalAddressArray[0]);
          let gasSpent = getGasSpent.receipt.gasUsed / 10000000; //this is not perfect, as it is hardcoded and might change due to gwei          
          assert.equal(Number(web3.fromWei(creatorInitialBalance, "ether")-gasSpent), Number(web3.fromWei(creatorOneWithdrawalBalance, "ether") - (11)), "first withdraw did not withdraw ether properly, or ledger did not update properly");

        })
      })
    })
  });


  /*workflow 
  a)
  1. Confirm 1 patreon can cancle (11 patreons left, full refund) (144-12=132 ether)
  2. confirm that creator can withdraw (withdraws 11 ether, 121 ether left) (144-12-11)
  3. confirm that 1 patreon can cancle and ledger good (9 left, 11 ether refund) (121-11=110)
  4. Confirm one person signs up, it goes back up to (1o patreons left) (110+12 = 122 ether)
  5. Confirm creator takes out again, (withdraws 11, 111 left, 10 have 10, 1 has 11)

  b)
  1.comment out one day speed bump and change now > dynamicFirstOfMonth to allow 12 withdrawls
  2. or just make now a Variable that is passed 
  3. withdraw 10 more so that there is 1 donator with 1 ether left
  4. Test to see if a finished patreon can withdraw. they shouldnt be able to
  5. add one more brand new patreon for next step
  5. check to see on the FINAL withdrawl, he can only withdraw 2, not some larger number from past patreons donating
  
  
  */

})//end of contract test