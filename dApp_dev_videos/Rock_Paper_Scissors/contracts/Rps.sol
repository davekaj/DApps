// simple rock paper scissors game on ethereum in a very naive implementation, just to showcase some basic features of Solidity

pragma solidity ^0.4.15;

contract RockPaperScissors {
    
    //A string that maps to a string that maps to an int
    mapping (string => mapping(string => int)) payoffMatrix;
    
    address player1;
    address player2;
    
    //State variables for players choice or rock, paper, or scissors (has a vulnerability)
    string public player1Choice;
    string public player2Choice;

    //Just there to prevent one player from registering twice
    modifier notRegisteredYet()
    {
        if (msg.sender == player1 || msg.sender == player2)
            revert();
        else
            _;
    }
    
    //To ensure that a certain amount of ether is sent with the transaction
    modifier sentEnoughCash(uint amount)
    {
        if (msg.value < amount)
            revert();
        else
            _;
    }
    
    
    //constructor function
    function RockPaperScissors() {
        payoffMatrix["rock"]["rock"] = 0;
        payoffMatrix["rock"]["paper"] = 2;
        payoffMatrix["rock"]["scissors"] = 1;
        payoffMatrix["paper"]["rock"] = 1;
        payoffMatrix["paper"]["paper"] = 0;
        payoffMatrix["paper"]["scissors"] = 2;
        payoffMatrix["scissors"]["rock"] = 2;
        payoffMatrix["scissors"]["paper"] = 1;
        payoffMatrix["scissors"]["scissors"] = 0;
    }
    
    

    
    function play(string choice) returns (int w) {
        if (msg.sender == player1)
            player1Choice = choice;
        else if (msg.sender == player2)
            player2Choice = choice;
        if (bytes(player1Choice).length != 0 && bytes(player2Choice).length != 0) {
            int winner = payoffMatrix[player1Choice][player2Choice];
            if (winner == 1)
                player1.transfer(this.balance);
            else if (winner == 2)
                player2.transfer(this.balance);
            else {
                player1.transfer(this.balance/2);
                player2.transfer(this.balance);
            }
             
            // unregister players and choices
            player1Choice = "";
            player2Choice = "";
            player1 = 0;
            player2 = 0;
            return winner;
        }
        else 
            return -1;
    }
    
    

//Getter Functions - only used to get values from the smart contract, not used for actual game play


    function getContractBalance () constant returns (uint amount) {
        return this.balance;
    }
    
    function getWinner() constant returns (int x) {
        return payoffMatrix[player1Choice][player2Choice];
    }
    
    
    function register()
        sentEnoughCash(5 ether)
        notRegisteredYet()
        payable 
    {
        if (player1 == 0)
            player1 = msg.sender;
        else if (player2 == 0)
            player2 = msg.sender;
    }
    
    function checkIfPlayer1() constant returns (bool x) {
        return msg.sender == player1;
    }
    
    function checkIfPlayer2() constant returns (bool x) {
        return msg.sender == player2;
    }

    
    function checkBothNotNull() constant returns (bool x) {
        return (bytes(player1Choice).length == 0 && bytes(player2Choice).length == 0);
    }

}