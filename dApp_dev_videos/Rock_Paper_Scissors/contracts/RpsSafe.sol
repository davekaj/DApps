pragma solidity ^0.4.13;


contract RpsAdvanced {
    mapping (string => mapping(string => int)) payoffMatrix;
    address player1;
    address player2;

    //varialbes that save the hash of the player which will be available publically on the blockchain, but won't reveal the players choice
    bytes32 player1ChoiceHash;
    bytes32 player2ChoiceHash;


    string public player1Choice;
    string public player2Choice;

    //used to end the game at a specific time, so once one player reveals, the other player 
    uint firstRevealTime;

    modifier notRegisteredYet()
    {
        if (msg.sender == player1 || msg.sender == player2)
            revert();
        else
            _;
    }

    modifier isRegistered()
    {
        if (msg.sender != player1 && msg.sender != player2)
            revert();
        else
            _;
    }
    
    modifier sentEnoughCash(uint amount)
    {
        if (msg.value < amount)
            revert();
        else
            _;
    }
    
    modifier validChoice(string choice)
    {
        // This is a workaround to comparing two strings in solidity. As comparing two strings does'nt always work, but the sha3 of them does work
        if (sha3(choice) != sha3("rock") && sha3(choice) != sha3("paper") && sha3(choice) != sha3("scissors"))
            revert();
        else
            _;
    }
    
    function RpsAdvanced() {   // constructor (spoiler alert: rename this if you rename the contract!)
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
    
    function register() payable
        sentEnoughCash(5)
        notRegisteredYet
    {
        if (player1 == 0)
            player1 = msg.sender;
        else if (player2 == 0)
            player2 = msg.sender;
    }

    function play(string choice, string randStr) 
        isRegistered
        validChoice(choice) //not sure how this works right now
    {
        if (msg.sender == player1)
            player1ChoiceHash = sha3(sha3(choice) ^ sha3(randStr));
        else if (msg.sender == player2)
            player2ChoiceHash = sha3(sha3(choice) ^ sha3(randStr));
    }
    
    function reveal(string choice, string randStr)
        isRegistered
        validChoice(choice)
    {
        // second player has 120 seconds after first player revealed
        if (bytes(player1Choice).length == 0 && bytes(player2Choice).length == 0)
            firstRevealTime == now;

        // if hashed choice + randStr is matching the initial one, choice is stored

        //bitwise xOR of the strings 
        if (msg.sender == player1 && sha3(sha3(choice) ^ sha3(randStr)) == player1ChoiceHash)
            player1Choice = choice;
        if (msg.sender == player2 && sha3(sha3(choice) ^ sha3(randStr)) == player2ChoiceHash)
            player2Choice = choice;
    }
    
    function checkWinner() {
        if (bytes(player1Choice).length != 0 && bytes(player2Choice).length != 0) {
            // if both revealed, obtain winner in usual way
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
        } else if (now > firstRevealTime + 120) {
            // if only one player revealed and time > start + timeout, winner is the one who revealed first
            if (bytes(player1Choice).length != 0)
                player1.transfer(this.balance);
            else if (bytes(player2Choice).length != 0)
                player2.transfer(this.balance);
        }
        
    }
    
    // HELPER FUNCTIONS
    function getMyBalance () constant returns (uint amount) {
        return msg.sender.balance;
    }
    
    function getContractBalance () constant returns (uint amount) {
        return this.balance;
    }
    
    function amIPlayer1() constant returns (bool x) {
        return msg.sender == player1;
    }
    
    function amIPlayer2() constant returns (bool x) {
        return msg.sender == player2;
    }
    
    // \HELPER FUNCTIONS
}