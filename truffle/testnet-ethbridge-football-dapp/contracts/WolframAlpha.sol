pragma solidity ^0.4.0;

import "usingOraclize.sol"


/*
   WolframAlpha example

   This contract sends a temperature measure request to WolframAlpha
*/



contract WolframAlpha is usingOraclize {
    
    string public temperature;
    
    event newOraclizeQuery(string description);
    event newTemperatureMeasure(string temperature);

    function WolframAlpha() payable {
        update();
    }
    
    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) throw;
        temperature = result;
        newTemperatureMeasure(temperature);
        // do something with the temperature measure..
    }
    
    function update() payable {
        newOraclizeQuery("Oraclize query was sent, standing by for the answer..");
        oraclize_query("WolframAlpha", "temperature in London");
    }
    
} 
                                           
