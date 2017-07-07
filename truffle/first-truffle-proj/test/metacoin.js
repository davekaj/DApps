var MetaCoin = artifacts.require("./MetaCoin.sol"); //because truffle has no way of detecting which contracts you'll need to interact with within your
//tests, you need to use this to determine which contract you need. artifcats.require is a truffle command. dont edit artifacts

contract('MetaCoin', function(accounts) { //use contract() instead of describe. enables clean room features. redeployed with a clean contract state
  it("should put 10000 MetaCoin in the first account", function() {
    return MetaCoin.deployed().then(function(instance) {
      return instance.getBalance.call(accounts[0]); //abstractions are read and write (calls and transactions) to the ethereum client
    }).then(function(balance) {
      assert.equal(balance.valueOf(), 9900, "10000 wasn't in the first account"); // assert is provided by truffle.Assert.sol library . you can include your own assert library if wanted
    });
  });
  it("should call a function that depends on a linked library", function() {// it is part of testing and also mocha in general 
    var meta;
    var metaCoinBalance;
    var metaCoinEthBalance;

    return MetaCoin.deployed().then(function(instance) { //????????????what exactly is deployed?????????????????
      meta = instance; //?????????????what is instance?????????????
      return meta.getBalance.call(accounts[0]);
    }).then(function(outCoinBalance) {
      metaCoinBalance = outCoinBalance.toNumber(); //i think to nummber is for bignumber
      return meta.getBalanceInEth.call(accounts[0]);
    }).then(function(outCoinBalanceEth) {
      metaCoinEthBalance = outCoinBalanceEth.toNumber();
    }).then(function() {
      assert.equal(metaCoinEthBalance, 2 * metaCoinBalance, "Library function returned unexpected function, linkage may be broken");
    });
  });
  it("should send coin correctly", function() {
    var meta;

    // Get initial balances of first and second account.
    var account_one = accounts[0];
    var account_two = accounts[1];

    var account_one_starting_balance;
    var account_two_starting_balance;
    var account_one_ending_balance;
    var account_two_ending_balance;

    var amount = 10;

    return MetaCoin.deployed().then(function(instance) {
      meta = instance;
      return meta.getBalance.call(account_one);
    }).then(function(balance) {
      account_one_starting_balance = balance.toNumber();
      return meta.getBalance.call(account_two);
    }).then(function(balance) {
      account_two_starting_balance = balance.toNumber();
      return meta.sendCoin(account_two, amount, {from: account_one});
    }).then(function() {
      return meta.getBalance.call(account_one);
    }).then(function(balance) {
      account_one_ending_balance = balance.toNumber();
      return meta.getBalance.call(account_two);
    }).then(function(balance) {
      account_two_ending_balance = balance.toNumber();

      assert.equal(account_one_ending_balance, account_one_starting_balance - amount, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance + amount, "Amount wasn't correctly sent to the receiver");
    });
  });
});
