pragma solidity ^0.4.0;

import "usingOraclize.sol";


contract WolframAlpha is usingOraclize {
    string public twoPlusTwo;
    uint public TEST = 4;

    
    event newOraclizeQuery(string description);
    event newAnswer(string answer);

    function WolframAlpha() payable {
        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475); //would have to remove while it is in testing 
        update();
    }
    
    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) revert();
        twoPlusTwo = result;
        newAnswer(twoPlusTwo);
        // do something with the temperature measure..
    }
    
    function update() payable {
        newOraclizeQuery("Oraclize query was sent, standing by for the answer..");
        oraclize_query("WolframAlpha", "two plus two");
    }

    function getAnswer () returns (uint) {
        return TEST;
    }

    function getOraclizeAnswer() returns (bytes32) {
        return sha3(twoPlusTwo);
    }
    
    function getOraclizeAnswerJS() returns (string) {
        return twoPlusTwo;
    }
} 
                                           
