/*
This is an example contract that helps test the functionality of the approveAndCall() functionality of HumanStandardToken.sol.
This one will throw and thus needs to propagate the error up.
*/
pragma solidity ^0.4.8;

contract SampleRecipientThrow {
  function () {
    throw;
  }
}


//OKAY THIS IS NOT A JUNK FUNCTION IT ACTUALLY JUST THROWS IT. BEAUTIFUL PEOPLE BEAUTFYL