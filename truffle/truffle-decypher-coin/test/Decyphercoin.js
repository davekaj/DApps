var DecypherCoin = artifacts.require("./DecypherCoin.sol");

contract('DecypherCoin', function (accounts) {
  it("should put 10000 DecypherCoin in the first account", function () {
    return DecypherCoin.deployed().then(function (instance) {
      return instance.balanceOf.call(accounts[0]);
    }).then(function (balance) {
      assert.equal(balance.valueOf(), 10000, "10000 wasn't in the first account");
    });
  });

  it("should send coin correctly", function () {
    var meta;

    // Get initial balances of first and second account.
    var account_one = accounts[0];
    var account_two = accounts[1];

    var account_one_starting_balance;
    var account_two_starting_balance;
    var account_one_ending_balance;
    var account_two_ending_balance;

    var amount = 2100;

    return DecypherCoin.deployed().then(function (instance) {
      meta = instance;
      return meta.balanceOf.call(account_one);
    }).then(function (balance) {
      account_one_starting_balance = balance.toNumber();
      return meta.balanceOf.call(account_two);
    }).then(function (balance) {
      account_two_starting_balance = balance.toNumber();
      return meta.transfer(account_two, amount, { from: account_one });
    }).then(function () {
      return meta.balanceOf.call(account_one);
    }).then(function (balance) {
      console.log(balance);
      account_one_ending_balance = balance.toNumber();
      return meta.balanceOf.call(account_two);
    }).then(function (balance) {
      console.log(balance);
      account_two_ending_balance = balance.toNumber();



      assert.equal(account_one_ending_balance, account_one_starting_balance - amount, "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance + amount, "Amount wasn't correctly sent to the receiver");
    });
  });


  it("should transfer based on approval", function () {
    var meta;

    // Get initial balances of first and second account.
    var spender = accounts[0];
    var owner = accounts[1];
    var newGuy = accounts[2];

    var spender_starting_balance;
    var owner_starting_balance;
    var spender_ending_balance;
    var owner_ending_balance;
    var newGuy_staring_balance;
    var newGuy_ending_balance;

    var allowanceGiven = 999;

    var endingAllowance;

    var amount = 45;

    return DecypherCoin.deployed().then(function (instance) {
      meta = instance;
      return meta.balanceOf.call(spender);
    }).then(function (balance) {//balance is of spender acct 0
      spender_starting_balance = balance.toNumber();
      console.log("spender Start: " + spender_starting_balance);
      return meta.balanceOf.call(newGuy);
    }).then(function (balance) {//balance is of spender acct 0
      newGuy_starting_balance = balance.toNumber();
      console.log("newguy start: " + newGuy_staring_balance);
      return meta.balanceOf.call(owner);
    }).then(function (balance) {  // balance is of owner acct 1
      owner_starting_balance = balance.toNumber();
      console.log("owner start: " + owner_starting_balance);
      return meta.approve(spender, allowanceGiven, { from: owner });
      //below must go everything in between 
    }).then(function () {
      return meta.allowance.call(owner, spender)
    }).then(function (allowance) {
      console.log("allowance: " + allowance);
      allowanceGiven = allowance.toNumber();
      return meta.transferFrom(owner, newGuy, amount)


      //below here we just once again call balances, turn them into variables
    }).then(function () {
      return meta.balanceOf.call(spender);
    }).then(function (balance) {
      spender_ending_balance = balance.toNumber();
      console.log("spender end: " + spender_ending_balance);
      return meta.balanceOf.call(owner);
    }).then(function (balance) {
      owner_ending_balance = balance.toNumber();
      console.log("owner end: " + owner_ending_balance);
      return meta.balanceOf.call(newGuy)
    }).then(function (balance) {
      newGuy_ending_balance = balance.toNumber();
      console.log("newGuy end: " + newGuy_ending_balance);
      return meta.allowance.call(owner, spender);
    }).then(function (newAllowance) {
      endingAllowance = newAllowance.toNumber();
      console.log("endingAllowance: " + endingAllowance);

      assert.equal(spender_ending_balance, spender_starting_balance, "Spenders accouunt is exactly the same");
      assert.equal(owner_ending_balance, owner_starting_balance - amount, "Amount wasn't correctly sent to the receiver");
      assert.equal(newGuy_ending_balance, newGuy_starting_balance + amount, "Amount wasn't correctly sent to the receiver");
      assert.equal(allowanceGiven, endingAllowance + amount, "Allowance was lessened");


    });
  });

  it("should mint more coins properly, and transfer the coins to acct0", function () {
    var minterAddress = accounts[0];

    var amountToMint = 88888;

    var minter_starting_balance;
    var minter_ending_balance;

    return DecypherCoin.deployed().then(function (instance) {
      decypher = instance;
      return decypher.balanceOf.call(minterAddress);
    }).then(function (balance) {
      console.log("balance start: " + balance);
      minter_starting_balance = balance.toNumber();
      return decypher.mint(amountToMint);
    }).then(function () {
      return decypher.balanceOf.call(minterAddress);
    }).then(function (balance) {
      minter_ending_balance = balance.toNumber();
      console.log("minter ending bal: " + minter_ending_balance);
      assert.equal(minter_ending_balance, minter_starting_balance + amountToMint, "minter should have 88888 more coins")
    });
  });

/*i cant figure out how to send ether to a payable function!!

  it("should let someone buy some coins with ether", function () {

    var buyPriceSetByMinter = .001;
    var sellPriCeSetByMinter = .000888;

    var contractAddress = "0x9a13299e4ff1f32e2181252f4f822d4a0560cdef";

    var guyBuyingcoins = accounts[6];
    var etherBalance6 = web3.fromWei(web3.eth.getBalance(web3.eth.accounts[6]));
    console.log("account 6 ether:" + etherBalance6);
    var guys_starting_coin_balance;
    var guys_ending_coin_balance;

    return DecypherCoin.deployed().then(function (instance){
      decypher = instance;
     // console.log(decypher);
      return decypher.setPrices(sellPriCeSetByMinter, buyPriceSetByMinter);
    }).then(function (){
      console.log("oy");
      //return web3.eth.sendTransaction({from: guyBuyingcoins, to: decypher.buy(), value: web3.toWei("10", "Ether")});
      return web3.eth.sendTransaction({from: accounts[6], to: decypher.address, value: web3.toWei("10", "Ether")});

      //return decypher.buy().send(web3.toWei(10, "ether"))
   }).then(function() {
      console.log("asasA");
      return decypher.balanceOf.call(guyBuyingcoins)
    }).then(function(balance){
      guys_ending_coin_balance = balance;
      console.log("ending guys coin balance: " + guys_ending_coin_balance);
    })

  });

*/





  it("should transfer minter address and then let him mint!", function () {
    var minterAddress = accounts[0];
    var newMinterAddress = accounts[5];

    var amountToMint = 9000000;

    var new_minter_starting_balance;
    var new_minter_ending_balance;



    return DecypherCoin.deployed().then(function (instance) {
      decypher = instance;
      return decypher.transferMinter(newMinterAddress);
    }).then(function () {
      return decypher.balanceOf.call(newMinterAddress);
    }).then(function (balance) {
      console.log("balance start: " + balance);
      minter_starting_balance = balance.toNumber();
      return decypher.mint(amountToMint, { from: newMinterAddress });
    }).then(function () {
      return decypher.balanceOf.call(newMinterAddress);
    }).then(function (balance) {
      minter_ending_balance = balance.toNumber();
      console.log("minter ending bal: " + minter_ending_balance);
      assert.equal(minter_ending_balance, minter_starting_balance + amountToMint, "minter should have 9000000 more coins")
    });
  });

});
