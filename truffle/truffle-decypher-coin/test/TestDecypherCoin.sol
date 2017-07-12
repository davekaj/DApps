pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/DecypherCoin.sol";

contract TestDecypherCoin {

  function testInitialBalanceUsingDeployedContract() {
    DecypherCoin meta = DecypherCoin(DeployedAddresses.DecypherCoin()); //deployedaddresses is a tuffle function that lets you find past deployed contracts

    uint expected = 10000;

   Assert.equal(meta.balanceOf(msg.sender), expected, "Owner should have 10000 DecypherCoin initially");
    
  //  Assert.equal(meta.name, expected, "total supply should be 10000");
  }

/*
  function testInitialBalanceWithNewDecypherCoin() {
    DecypherCoin meta = new DecypherCoin();

    uint expected = 10000;

    Assert.equal(meta.balanceOf(tx.origin), expected, "Owner should have 10000 DecypherCoin initially");
  }
*/
}
