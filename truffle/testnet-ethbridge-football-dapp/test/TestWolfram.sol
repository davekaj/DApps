pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/WolframAlpha.sol";

contract TestWolfram {

  function testTwoPlusTwo() {
    Wolfram wa = WolframAlpha(DeployedAddresses.WolframAlpha());

    uint expected = 4;

    Assert.equal(wa.getAnswer(tx.origin), expected, "Owner should have 10000 MetaCoin initially");
  }
/*
  function testInitialBalanceWithNewMetaCoin() {
    MetaCoin meta = new MetaCoin();

    uint expected = 10000;

    Assert.equal(meta.getBalance(tx.origin), expected, "Owner should have 10000 MetaCoin initially");
  }

}
*/