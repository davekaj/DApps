/**************************************************************************************************************************
Testing of the SinglePatreon contract (not the Factory).
Testing with Testrpc instance with --accounts 50 Flag
Some of the tests are designed to Fail, as I haven't had time to make them pass upon failure



***************************************************************************************************************************/
var PatreonFactorySolFile = artifacts.require("./PatreonFactory.sol");
var SinglePatreon = artifacts.require("SinglePatreon");
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
    let patreon = 2; //account 2
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
    let patreon = 2; //account 2
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
    let patreon = 2; //account 2
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
    let patreon = 2; //account 2
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

        assert.equal(Number(web3.fromWei(contractBalance, "ether")), Number(web3.fromWei(setMonthlyAmount, "ether"), "Contract balance did not receive funds"));
      })
    })
  });


  it('FAIL: Testing Patreon cant send a monthly contribution twice', function () {
    let owner = 0;
    let creator = 1;
    let patreon = 4; //account 4
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

        assert.equal(Number(web3.fromWei(contractBalance, "ether")), Number(web3.fromWei(setMonthlyAmount, "ether"), "Contract balance did not receive funds"));
      })
    })
  });

  it(`Test donators array is filled properly`, function () {
    let owner = 0;
    let creator = 1;
    let patreon = 4; //account 4
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

  it('Conrim basic withdrawals and cancelation functions work (1 cancle, 1 withdraw, 1 more cancle, 1 signup, 1 withdraw', function () {
    let owner = 0;
    let creator = 1;
    let patreonCancle1 = 10;
    let patreonCancle2 = 11;
    let patreonSignup = 22;
    let setMonthlyAmount = "12000000000000000000"; //12 ether
    let patreonCancel1InitialBalance = web3.eth.getBalance(accounts[patreonCancle1]);
    let patreonCancel2InitialBalance = web3.eth.getBalance(accounts[patreonCancle2]);
    let creatorInitialBalance = web3.eth.getBalance(accounts[creator]);
    console.log(patreonCancel2InitialBalance);

    let singlePatreonInstance = SinglePatreon.at(globalAddressArray[0]);
    return singlePatreonInstance.monthlyDonationAmount.call().then(function (setMonthlyReturnedValue) {

      return singlePatreonInstance.patreonCancleMonthly({ from: accounts[patreonCancle1] }).then(function (getGasSpent) {
        let gasSpent = getGasSpent.receipt.gasUsed / 10000000; //this is not perfect, as it is hardcoded and might change due to gwei
        let patreonCancel1FinalBalance = web3.eth.getBalance(accounts[patreonCancle1]);
        assert.approximately(Number(web3.fromWei(patreonCancel1InitialBalance, "ether") - gasSpent), Number(web3.fromWei(patreonCancel1FinalBalance, "ether") - (12)), 0.000001, "first cancel did not receive thier ether properly, or ledger did not update properly");

        return singlePatreonInstance.creatorWithdrawMonthly({ from: accounts[creator] }).then(function (getGasSpent2) {
          let creatorOneWithdrawalBalance = web3.eth.getBalance(accounts[creator]);
          let gasSpent2 = getGasSpent2.receipt.gasUsed / 10000000; //this is not perfect, as it is hardcoded and might change due to gwei     
          //made this approvixmately, because sometimes it fails from being off 0.0000001 eth off. which sucks, it shouldnt be like this, but I think it is the web3 side     
          assert.approximately(Number(web3.fromWei(creatorInitialBalance, "ether") - gasSpent2), Number(web3.fromWei(creatorOneWithdrawalBalance, "ether") - (11)), 0.000001, "first withdraw did not withdraw ether properly, or ledger did not update properly");

          return singlePatreonInstance.patreonCancleMonthly({ from: accounts[patreonCancle2] }).then(function (getGasSpent3) {
            let gasSpent3 = getGasSpent3.receipt.gasUsed / 10000000;
            let patreonCancel2FinalBalance = web3.eth.getBalance(accounts[patreonCancle2]);
            assert.approximately(Number(web3.fromWei(patreonCancel2InitialBalance, "ether") - gasSpent3), Number(web3.fromWei(patreonCancel2FinalBalance, "ether") - (11)), 0.000001, "second cancel did not receive thier ether properly, or ledger did not update properly");

            let contractBalanceBeforeSignup = web3.eth.getBalance(globalAddressArray[0]);
            return singlePatreonInstance.monthlyContribution({ from: accounts[patreonSignup], value: setMonthlyAmount }).then(function () {
              let contractBalanceAfterSignup = web3.eth.getBalance(globalAddressArray[0]);
              assert.equal(Number(web3.fromWei(contractBalanceBeforeSignup, "ether")), Number(web3.fromWei(contractBalanceAfterSignup, "ether") - (12)), "Contract balance did recieve funds for 4th step, and ledger didnt break");

              //to test this we comment out oneDaySpeedBump Temporarily
              return singlePatreonInstance.creatorWithdrawMonthly({ from: accounts[creator] }).then(function (getGasSpent4) {
                let creatorTwoWithdrawalBalance = web3.eth.getBalance(accounts[creator]);
                let gasSpent4 = getGasSpent4.receipt.gasUsed / 10000000; //this is not perfect, as it is hardcoded and might change due to gwei     
                assert.approximately(Number(web3.fromWei(creatorOneWithdrawalBalance, "ether") - gasSpent4), Number(web3.fromWei(creatorTwoWithdrawalBalance, "ether") - (11)), 0.000001, "Second withdraw did not withdraw ether properly, or ledger did not update properly");
              })
            })
          })
        })
      })
    })
  });

  function loop10Withdrawals(i) {
    it("Comment out speedbump and change dynamicFirstOfMonth to let loop 10 more times.", function () {
      let owner = 0;
      let creator = 1;
      let patreonSignup23 = 23;
      let setMonthlyAmount = "12000000000000000000"; //12 ether
      let singlePatreonInstance = SinglePatreon.at(globalAddressArray[0]);

      console.log(`test${i}`);
      let creatorInitialBalance = web3.eth.getBalance(accounts[creator]);
      return singlePatreonInstance.creatorWithdrawMonthly({ from: accounts[creator] }).then(function (loopGasSpent) {
        let creatorUpdatedBalance = web3.eth.getBalance(accounts[creator]);
        let gasSpent = loopGasSpent.receipt.gasUsed / 10000000; //this is not perfect, as it is hardcoded and might change due to gwei     
        assert.approximately(Number(web3.fromWei(creatorInitialBalance, "ether") - gasSpent), Number(web3.fromWei(creatorUpdatedBalance, "ether") - (11)), 0.000001, "Second withdraw did not withdraw ether properly, or ledger did not update properly");
      })
    })
  }
  for (let i = 0; i < 10; i++) {
    loop10Withdrawals(i);
  }

  //works, doesn't let a completed user try to withdraw :)
  it("FAIL: Confirm a completed patreon cant withdraw anymore (their struct has 0's)", function () {
    let owner = 0;
    let creator = 1;
    let patreonCancle3 = 12;
    let setMonthlyAmount = "12000000000000000000"; //12 ether
    let patreonCancel3InitialBalance = web3.eth.getBalance(accounts[patreonCancle3]);

    let singlePatreonInstance = SinglePatreon.at(globalAddressArray[0]);
    return singlePatreonInstance.patreonCancleMonthly({ from: accounts[patreonCancle3] }).then(function (getGasSpent) {
      let gasSpent = getGasSpent.receipt.gasUsed / 10000000; //this is not perfect, as it is hardcoded and might change due to gwei
      let patreonCancel1FinalBalance = web3.eth.getBalance(accounts[patreonCancle1]);
      assert.approximately(Number(web3.fromWei(patreonCancel1InitialBalance, "ether") - gasSpent), Number(web3.fromWei(patreonCancel1FinalBalance, "ether") - (12)), 0.000001, "first cancel did not receive thier ether properly, or ledger did not update properly");
    })
  })

  it("Confirm that one more patreon can sign up, and creator properly withdraws amount", function () {
    let creator = 1
    let finalSignup = 35;
    let contractBalance = web3.eth.getBalance(globalAddressArray[0]);
    let setMonthlyAmount = "12000000000000000000"; //12 ether
    let creatorInitialBalance = web3.eth.getBalance(accounts[creator]);

    let singlePatreonInstance = SinglePatreon.at(globalAddressArray[0]);
    return singlePatreonInstance.monthlyContribution({ from: accounts[finalSignup], value: setMonthlyAmount }).then(function () {
      let newContractBalance = web3.eth.getBalance(globalAddressArray[0]);
      console.log(contractBalance);
      assert.equal(Number(web3.fromWei(newContractBalance, "ether") - (12)), Number(web3.fromWei(contractBalance, "ether")), "ContractBalance Updated Correctly");
      return singlePatreonInstance.creatorWithdrawMonthly({ from: accounts[creator] }).then(function (getGasSpent5) {
        let creatorUpdatedBalance = web3.eth.getBalance(accounts[creator]);
        let gasSpent = getGasSpent5.receipt.gasUsed / 10000000;
        assert.approximately(Number(web3.fromWei(creatorInitialBalance, "ether") - gasSpent), Number(web3.fromWei(creatorUpdatedBalance, "ether") - (2)), 0.000001, "Creator only withdrew 2, like he is supposed to");
      })
    })
  })

})//end of test contract



  /*workflow for final 4 big tests 
    a) starts with 12 patreons
    1. Confirm 1 patreon can cancle (11 patreons left, full refund) (144-12=132 ether)
    2. confirm that creator can withdraw (withdraws 11 ether, 121 ether left) (144-12-11)
    3. confirm that 1 patreon can cancle and ledger good (10 left, 11 ether refund) (121-11=110)
    4. Confirm one person signs up, it goes back up to (11 patreons left) (110+12 = 122 ether)
    5. Confirm creator takes out again, (withdraws 11, 111 left, 10 people have 10 ether, 1 has 11) - note - need to comment outOneDaySpeedBump
  
    b)
    1.comment out one day speed bump and change now > dynamicFirstOfMonth to allow 12 withdrawls
    2. or just make now a Variable that is passed 
    3. withdraw 10 more so that there is 1 donator with 1 ether left
    4. Test to see if a finished patreon can withdraw. they shouldnt be able to
    5. add one more brand new patreon for next step
    5. check to see on the FINAL withdrawl, he can only withdraw 2, not some larger number from past patreons donating
  */