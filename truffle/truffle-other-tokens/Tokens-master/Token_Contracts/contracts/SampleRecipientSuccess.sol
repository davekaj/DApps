/*
This is an example contract that helps test the functionality of the approveAndCall() functionality of HumanStandardToken.sol.
This one assumes successful receival of approval.
*/
pragma solidity ^0.4.8;

contract SampleRecipientSuccess {
  /* A Generic receiving function for contracts that accept tokens */
  address public from;
  uint256 public value;
  address public tokenContract;
  bytes public extraData;

  event ReceivedApproval(uint256 _value);

  function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData) {
    from = _from;
    value = _value;
    tokenContract = _tokenContract;
    extraData = _extraData;
    ReceivedApproval(_value);
  }
}


//SO THIS KEEPS GETTING CALLED IN THE HUMANSTANDARDTOKEN.JS TEST FILE. OKAY SO IT ASSUMES SUCCESSFUL RECEIVAL OF APPROVAL
// I THINK IT IS MIMICKING IF IT ACTUALLY WENT TO SOME PERSON WHO LANUCHED THE CONTRACT, AND THEY MANUALLY SAID YES I APPROVE OF THIS DECISION
// HOWEVER THIS IS NOT REALLY NECESSARY SO WE JUT LET IT KINDA DO SOME SHIT TO APPROVE 