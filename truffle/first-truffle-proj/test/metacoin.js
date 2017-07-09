var MetaCoin = artifacts.require("./MetaCoin.sol"); //because truffle has no way of detecting which contracts you'll need to interact with within your
//tests, you need to use this to determine which contract you need. artifcats.require is a truffle command. dont edit artifacts

contract('MetaCoin', function (accounts) { //use contract() instead of describe. enables clean room features. redeployed with a clean contract state



//you write what you want to see in the first argumetnet of it 
  it("should put 10000 MetaCoin in the first account", function () {
    return MetaCoin.deployed().then(function (instance) {
      return instance.getBalance.call(accounts[5]); //abstractions are read and write (calls and transactions) to the ethereum client
    }).then(function (balance) {
      assert.equal(balance.valueOf(), 9900, "10000 wasn't in the first account"); // assert is provided by truffle.Assert.sol library . you can include your own assert library if wanted
    });// you put what you dont want to see in asserts last argument
  });




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




  it("should send coin correctly", function () { //each it is a test that returns some value to me 
    var meta;

    // Get initial balances of first and second account.
    var account_one = accounts[0];
    var account_two = accounts[1];
    console.log(account_two + "asdasasdA");

    var account_one_starting_balance;
    var account_two_starting_balance;
    var account_one_ending_balance;
    var account_two_ending_balance;

    var amount = 10;

    return MetaCoin.deployed().then(function (instance) {
      meta = instance;
      return meta.getBalance.call(account_one);
    }).then(function (balance) {
      account_one_starting_balance = balance.toNumber();
      return meta.getBalance.call(account_two);
    }).then(function (balance) {
      account_two_starting_balance = balance.toNumber();
      return meta.sendCoin(account_two, amount, { from: account_one });
    }).then(function () {
      return meta.getBalance.call(account_one);
    }).then(function (balance) {
      account_one_ending_balance = balance.toNumber();
      return meta.getBalance.call(account_two);
    }).then(function (balance) {
      account_two_ending_balance = balance.toNumber();
      console.log(account_one_starting_balance);
      console.log(account_one_ending_balance);
      console.log(account_two_starting_balance);
      console.log(account_two_ending_balance);
      
      assert.equal(account_one_ending_balance, account_one_starting_balance - amount, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance + amount, "Amount wasn't correctly sent to the receiver");
    });
  });




  it("davids test, sending coin again", function () { //each it is a test that returns some value to me 
    var meta;

    // Get initial balances of first and second account.
        var account_one = accounts[0];

    var account_three = accounts[2];
    console.log(account_three);

    var account_one_starting_balance;
    var account_one_ending_balance;

    var account_three_starting_balance;
    var account_three_ending_balance;

    var amount3 = 1000;

    return MetaCoin.deployed().then(function (instance) {
      meta = instance;
      return meta.getBalance.call(account_one); // looks like here they are actullay just getting the balacnes, and chaining hte promises
    }).then(function (balance) {
      account_one_starting_balance = balance.toNumber();
      return meta.getBalance.call(account_three);
    }).then(function (balance) {
      account_three_starting_balance = balance.toNumber();
      return meta.sendCoin(account_three, amount3, { from: account_one }); //calling the function sendCoin from MetaCon.sol
    }).then(function () {
      return meta.getBalance.call(account_one);
    }).then(function (balance) {
      account_one_ending_balance = balance.toNumber();
      return meta.getBalance.call(account_three);
    }).then(function (balance) {
      account_three_ending_balance = balance.toNumber();

            console.log(account_one_starting_balance);
      console.log(account_one_ending_balance);
      console.log(account_three_starting_balance);
      console.log(account_three_ending_balance);

      assert.equal(account_one_ending_balance, account_one_starting_balance - amount3, "Amount wasn't correctly taken from the sender");
      assert.equal(account_three_ending_balance, account_three_starting_balance + amount3, "Amount wasn't correctly sent to the receiver");

//note that tests are not run seperately. i pulled money from account one, and then when we transferred to account three, it was still missing that amount



    });
  });
});
