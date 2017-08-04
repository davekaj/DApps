pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/WolframAlpha.sol";

contract TestWolfram {

  function testTwoPlusTwo() {
    WolframAlpha wa = WolframAlpha(DeployedAddresses.WolframAlpha());

    uint expected = 4;
    //bytes32 expected = sha3("4");

    Assert.equal(wa.getAnswer(), expected, "Two Plus Two Should Equal Four");
  }
/*
  function testInitialBalanceWithNewMetaCoin() {
    MetaCoin meta = new MetaCoin();

    uint expected = 10000;

    Assert.equal(meta.getBalance(tx.origin), expected, "Owner should have 10000 MetaCoin initially");
  }



*/

}