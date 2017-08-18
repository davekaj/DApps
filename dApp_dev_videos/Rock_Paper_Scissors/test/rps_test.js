var Rps = artifacts.require("./Rps.sol"); //because truffle has no way of detecting which contracts you'll need to interact with within your
//tests, you need to use this to determine which contract you need. artifcats.require is a truffle command. dont edit artifacts

contract('RPS', function (accounts) { //use contract() instead of describe. enables clean room features. redeployed with a clean contract state


/*
//you write what you want to see in the first argumetnet of it 
  it("should put 10000 MetaCoin in the first account", function () {
    return MetaCoin.deployed().then(function (instance) {
      return instance.getBalance.call(accounts[5]); //abstractions are read and write (calls and transactions) to the ethereum client
    }).then(function (balance) {
      assert.equal(balance.valueOf(), 9900, "10000 wasn't in the first account"); // assert is provided by truffle.Assert.sol library . you can include your own assert library if wanted
    });// you put what you dont want to see in asserts last argument
  });

*/

  it("should register account 1", function(){
    return Rps.deployed().then(function (instance){
      return instance.register({from:accounts[0],  value: web3.toWei("10", "Ether")});
    }).then(function (){
      assert.equal(accounts[0], instance.returnPlayer1(), "player1 wasnt assinged to account 1")
    })
  });

  it("should register account 2", function(){
    return Rps.deployed().then(function (instance){
      return instance.register({from:accounts[1],  value: web3.toWei("10", "Ether")});
    }).then(function (){
      assert.equal(accounts[1], instance.returnPlayer1(), "player2 wasnt assinged to account 2")
    })
  });


/*

  it("should call a function that depends on a linked library", function () {// it is part of testing and also mocha in general 
    var meta;
    var metaCoinBalance;
    var metaCoinEthBalance;

    return MetaCoin.deployed().then(function (instance) { //????????????what exactly is deployed?????????????????
      meta = instance; //?????????????what is instance????????????? .... it looks like it is the instance of the contract
      return meta.getBalance.call(accounts[0]);
    }).then(function (outCoinBalance) {
      metaCoinBalance = outCoinBalance.toNumber(); //i think to nummber is for bignumber
      return meta.getBalanceInEth.call(accounts[0]);
    }).then(function (outCoinBalanceEth) {
            console.log(meta.getBalanceInEth.call(accounts[0]));
      metaCoinEthBalance = outCoinBalanceEth.toNumber();
    }).then(function () {
      assert.equal(metaCoinEthBalance, 2 * metaCoinBalance, "Library function returned unexpected function, linkage may be broken");
    });
  });

*/


});
