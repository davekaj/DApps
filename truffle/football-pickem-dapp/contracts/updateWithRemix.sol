pragma solidity ^ 0.4.12;


import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "github.com/Arachnid/solidity-stringutils/strings.sol";

contract SingleGameContract is usingOraclize {

    using strings for *; //what is this???????


    /*************************modifiers*********************************/
    modifier noEther {if (msg.value > 0) throw; _; }
    modifier onlyOwner {if (msg.sender != owner) throw; _; }
    modifier onlyOraclize {if (msg.sender != oraclize_cbAddress()) throw; _; }
	modifier onlyInState (uint _entryID, stateOfEntry _state) {
		entryInformation instance = entries[_entryID];
		if (instance.state != _state) throw;
		_;
	}
    modifier notInMaintenance {
        healthCheckContract();
        if (maintenance_mode >= maintenance_Emergency) throw;
        _;
    }
    modifier noRentry {
        if (reentryGuard) throw;
        reentryGuard = true;
        _;
        reentryGuard = false;
    }

	/*enums are one way to create a user defined type in Solidity. they are explicitly convertible to and from all integer types, but implicit convestion
	is not allowed. the explicit converstions check the value ranges at runtime and a failure causes an exception. enums need at least one number*/
    enum stateOfEntry {Applied, Accepted, Winner, Loser, Declined, SendingFailure } //00 01 02 03 04 05
    enum oraclizeState { GetHome, GetAway } //00 01


    //events
    event LOG_entryApplied (
        uint entryID, //first entry would be 1, 2. links to gameID
        address user, //might be a duplicate variable, if you bet on two diff games
        string homeOrAway //H or A
    );
    event LOG_entryAccepted(
        uint entryID
    );
    event LOG_entryWinner(
        uint entryID,
        uint amount
    );
    event LOG_entryLoser(
        uint entryID
    );
    event LOG_entryDeclined(
        uint entryID,
        string reason //because of compiler i switched this to string, not bytes32. and for manual payout and sendfail
    );
    event LOG_entryManualPayout( //will need to add later
        uint entryID,
        string reason
        //does this need uint amount? it doesnt in the other policy 
    );
    event LOG_SendFail(
        uint entryID,
        string reason
    );
    //oraclize events
    event LOG_OraclizeCall(
        uint entryID,
        bytes32 queryId,//used to interact with oracle
        string oraclize_url
    );
    event LOG_OraclizeCallback(
        uint entryID,
        bytes32 queryId,
        string result, //what the oracle brings back
        bytes proof //the proof thing which i dont undertand fully
    );

    //this is there to check if the amount of ether in the contract acutally lines up with what the payout is. 
    event LOG_HealthCheck(
        bytes32 message,
        int diff,
        uint balance,
        int ledgerBalance 
    );


    /******************Constants*********************************************************************************************************************************/
    //not used: contractdeadline, totalEntries

    //general constants for the whole contract
    uint constant betInEther = 0.1 ether; // should be like, 100 finney actually
    //this would be the end of the 2017 season. lets make it 2017. i doubt the contract would not be updated 
    uint contractDeadline;
    //gas constant for oraclize. set at 500000 for now, might be changed
    uint constant oraclizeGas = 500000;
    //for the guy updating it
    uint8 constant percentFeeForDapp = 1; //1%
    //for any errors in calcs, so theres a fund on reserve to payout
    uint8 constant percentFeeForErrors = 1; //1%
    //a tally of how many people have entered
    uint totalEntries;

    // account numbers for the internal ledger

    //sum of all entry fees from users. will be a multiple of entries entered
    uint8 constant poolFund = 0;
    //small reward fund that is kept in case some accounting errors happen and things needs to be rounded off
    uint8 constant errorFund = 1;
    //balance of the contract itself
    uint8 constant contractBalance = 2;
    //account to pay for updating the dapp code peridically 
    uint8 constant updatingDappFund = 3;
    // account holding ether to pay for oraclize calls
    uint8 constant oracalizeFeesFund = 4;


    //maintenance modes
    uint8 constant maintenance_None = 0;
    uint8 constant maintenance_BalTooHigh = 1;
    uint8 constant maintenance_Emergency = 255;

    //api strings, hardcoded with a specific date
    string constant oraclizeOneGameApiStart = "json(http://api.sportradar.us/nfl-ot1/games/";
    string constant oraclizeOneGameApiHome = "/boxscore.json?api_key=4dm7ds2degn9av2yp9ayqgtz).summary.home.points";
    string constant oraclizeOneGameApiAway = "/boxscore.json?api_key=4dm7ds2degn9av2yp9ayqgtz).summary.away.points";

    struct entryInformation {
        //unique public addresss of entry
        address user;
        //H or A
        string chooseHomeOrAway;
        //1000 finney is one ether
        uint etherSentByUser;
        //pointer to the game that is being bet on . it is same as the actual tag from the website
        bytes32 gameID;
        //status fields:
        stateOfEntry state;
        // 7 - time of last state change
        uint stateTime;
        // 8 - state change message/reason
        string stateMessage; //HAD TO CHANGE THIS TO STRING CUZ COMPILER
        // 9 - TLSNotary Proof from oraclize
        bytes proof;
    }

    //has the information about the game itself, and the results, which is enough information to determine winner or loser. 
    struct game {

        //the tag that allows for a specific game to be called. will need to be gathered from front end somehow. for testing in truffle it will be written in test
        bytes32 gameAPITag;
        //receive the score from oracle and saved. home score is called first, then away gets called right after, in a callback function
        uint homeScore;
        //receive from oracle and saved
        uint awayScore;

    }

    //this is created right when oraclize is actually called. from the internal function. this is used to relate data back and forth. not created in __Callback. used in __callback
    struct oraclizeCallback {

        // for which entry have we called?
        uint entryID;
        // for which purpose did we call? {GetHome | GetAway}
        oraclizeState oState;
        uint oraclizeTime;
        bytes32 oraclize_gameID;

    }

    //contract variables that are needed to navigate and connec the data from oracle and blockchain
    // guy who publishes contract (me)
    address public owner;
    //table of everyone who has entered
    entryInformation[] public entries;
    //lookup entryIDs from entry public addresses. THIS MAKES SENSE NOW, CUZ ONE ADDRESS COULD HAVE AN EXPANDING UINT[] CUZ HE ENTERED MORE THAN ONCE, FOR ONE WEEK
    mapping(address => uint[]) public entryIDs;
    //lookup entryIDs from queryIDs
    mapping(bytes32 => oraclizeCallback) public oraclizeCallbacks;
    //keeps track of how many GAMES have been initiated to be bet on. NOT REALLY SURE IF THIS IS NEEDED?????????????????????
    mapping(bytes32 => game) public games;

    //Internal ledger
    int[5] public ledger;

    //Mutex
    bool public reentryGuard;
    uint8 public maintenance_mode;




/***************************************************************************FUNCTIONS**********************************************************************************/

    function healthCheckContract() internal {
        int diff = int(this.balance - msg.value) + ledger[contractBalance];
        if (diff == 0) {
            return; // the amount being paid out and the contract amount are equal. nothing wrong with contract
        }
        if (diff > 0) {
            LOG_HealthCheck('Balance is too high', diff, this.balance, ledger[contractBalance]);
            maintenance_mode = maintenance_BalTooHigh;
        } else {
            LOG_HealthCheck('Balance too low', diff, this.balance, ledger[contractBalance]);
            maintenance_mode = maintenance_Emergency;
        }
    }


    //I DONT UNDERSTAND THIS FUNCTION AT ALL 
    function payWinner() onlyOwner {
        if (!owner.send(this.balance)) throw; // i think this means if this gets called and we are not the owner trying to send the balance, throw it!
        maintenance_mode = maintenance_Emergency; // don't accept any policies		
    }

    //update the internal ledger's 5 accounts
    function bookKeeping(uint8 _from, uint8 _to, uint _amount) internal {
        ledger[_from] -= int(_amount);
        ledger[_to] += int(_amount);
    }

    //if ledger needs to be corrected, it can be by moving around erros funds or fees. or withdrawing update DApp fees
    function audit(uint8 _from, uint8 _to, uint _amount) onlyOwner {
        bookKeeping(_from, _to, _amount);
    }

    //anyone can call and see this. all it does is return a function
    function getentryCount(address _user) constant returns (uint _count) {
        return entries.length;
    }

    //anyone can call and see this. all it does is return a function
    function getentryGameCount(address _user) constant returns (uint _count) {
        return entryIDs[_user].length;
    }


    //the problem is for this each preimum is unique. mine is a whole pool. so it will have to be used differently
    function getOperatingCostsAndRemainingPool() internal returns (uint) {

        uint entryFee = msg.value;
        uint updateDappFee = entryFee * percentFeeForDapp / 100;
        uint errorFee = entryFee * percentFeeForErrors / 100;

        bookKeeping(contractBalance, poolFund, entryFee);
        bookKeeping(poolFund, updatingDappFund, updateDappFee);
        bookKeeping(poolFund, errorFund, errorFee);

        return (uint(entryFee - updateDappFee - errorFee));
    }

    //constructor
    function SingleGameContract() payable {
        owner = msg.sender;
        reentryGuard = false;
        maintenance_mode = maintenance_None;

        //initialze the contract by putting in the start that I want to have for an error fund for backup
        bookKeeping(contractBalance, errorFund, msg.value);
       // oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS); //need to read oraclize contract to dig into this THIS IS MAKING CONTRACT FAIL, GREENED IT OUT
    }

    //1470614500 testing this just so it passes
    //c8dc876a-099e-4e95-93dc-0eb143c6954f the tag of the game we are inspecting. seattle 12, miami 10 
    function newEntry(bytes32  _gameTagFromApi, string _homeOrAway, uint _startTimeOfGame) notInMaintenance payable {
    
        uint _testingAugust2016 = 1470614400; //testing phase, to work with old games, the current games dont exist
        uint _startOf2017Season = 1501702200; //august 2nd, 730pm 2017
        uint _endOf2017Season = 1514808000; //january 1st, noon, 2018


        //right now must send .1 ether. no point in really changing this for now 
        if (msg.value != 100 finney) {
            LOG_entryDeclined(0, 'All entries must bet 0.1 ether');
            if (!msg.sender.send(msg.value)) {
                LOG_SendFail(0, 'newEntry sending of EtherFailed (1)');
            }
            return;
        }
        if (_startTimeOfGame > now + 1 hours || _startTimeOfGame < _testingAugust2016 || _startTimeOfGame > _endOf2017Season){
            LOG_entryDeclined(0, 'Must be 2017 season and at least 1 hour before 1st game of week');
            if (!msg.sender.send(msg.value)) {
                LOG_SendFail(0, 'newEntry sendback failed (2)');
            }
            return;
        }

        bytes32  gameID = _gameTagFromApi;
        game gameMapping = games[gameID];

        //where entries is a struct with ~5 values 
        uint entryID = entries.length++;//figure out entryID number based on previous ones that exist
        entryIDs[msg.sender].push(entryID); //where entryIDs is a mapping of addresses to entryIDS for loookup
        entryInformation instance = entries[entryID];

        instance.user = msg.sender;
        instance.etherSentByUser = getOperatingCostsAndRemainingPool();
        instance.gameID = gameID;
        instance.chooseHomeOrAway = _homeOrAway;

        instance.state = stateOfEntry.Applied;
        instance.stateMessage = "Game bet applied successfully by entry";
        instance.stateTime = now;
        LOG_entryApplied(entryID, msg.sender, _homeOrAway); //do i need to add weekly games to here

        //now youve entered, but we gotta see if you string is okay, then log entryAccepted
        acceptUserEntry(entryID);

    }

    /* decline will BE ADDED IN AFTER. I wanna get the app to work before I try this
    function decline() {

    }
    */

    //underwrite
    function acceptUserEntry(uint _entryID) onlyInState(_entryID, stateOfEntry.Applied) { //_entryID here is used to get all information from the entryID, so i dont have to pass a ton of data to here
        entryInformation instance = entries[_entryID];
        checkOneHomeGame(_entryID, instance.gameID);
        //logic to check if the actual entry is valid. this is not part of MVP so later
        LOG_entryAccepted(_entryID);
    }


    function checkOneHomeGame(uint _entryID, bytes32 _gameID) {
        string memory _tempFixGameID = "c8dc876a-099e-4e95-93dc-0eb143c6954f"; // needed because compiler wont let me use a string instead of bytes32, which is needed for strConcat from oracle contract
        string memory oraclize_url_home = strConcat(oraclizeOneGameApiStart, _tempFixGameID, oraclizeOneGameApiHome);
        bytes32 queryID = oraclize_query("URL", oraclize_url_home, oraclizeGas);
        uint _oraclizeTime = now;

        //dont get the negative here
        bookKeeping(oracalizeFeesFund, contractBalance, uint((-ledger[contractBalance]) - int(this.balance)));
        oraclizeCallbacks[queryID] = oraclizeCallback(_entryID, oraclizeState.GetHome, _oraclizeTime, _gameID);

        LOG_OraclizeCall(_entryID, queryID, oraclize_url_home);
    }

    function checkOneAwayGame(uint _entryID, bytes32 _gameID) {
        string memory _tempFixGameID = "c8dc876a-099e-4e95-93dc-0eb143c6954f"; // needed because compiler wont let me use a string instead of bytes32, which is needed for strConcat from oracle contract
        string memory oraclize_url_away = strConcat(oraclizeOneGameApiStart, _tempFixGameID, oraclizeOneGameApiAway);
        bytes32 queryID = oraclize_query("nested", oraclize_url_away, oraclizeGas);
        uint _oraclizeTime = now;


        //dont get the negative here
        bookKeeping(oracalizeFeesFund, contractBalance, uint((-ledger[contractBalance]) - int(this.balance)));
        oraclizeCallbacks[queryID] = oraclizeCallback(_entryID, oraclizeState.GetAway, _oraclizeTime, _gameID);

        LOG_OraclizeCall(_entryID, queryID, oraclize_url_away);
    }



    /* i have the query ID, which two are linked to a single entry ID,
        which has a game chosen and home or away, 
        which is linked to the struct game, which has weather H or A won,
        which is gathered from the oracle calls, and their results.
    
        queryID && result ---> entryID ---> HorW && Struct Game ---> Scores/Winner


        you can look up struct oraclizeCallbacks to get entryID from QueryID
        you can look up the game struct with gameID in entry ID
    */
    function __callBack(bytes32 _queryId, string _result, bytes _proof) onlyOraclize noRentry {
        oraclizeCallback memory instance = oraclizeCallbacks[_queryId];

        LOG_OraclizeCallback(instance.entryID, _queryId, _result, _proof);

        if (instance.oState == oraclizeState.GetHome) {
            game saveHomeScoreInstance = games[instance.oraclize_gameID];
            uint homeStringResultToUint = parseInt(_result);
            saveHomeScoreInstance.homeScore = homeStringResultToUint;
            checkOneAwayGame(instance.entryID, instance.oraclize_gameID);
        } else {
            game saveAwayScoreInstance = games[instance.oraclize_gameID];
            uint awayStringResultToUint = parseInt(_result);
            saveAwayScoreInstance.awayScore = awayStringResultToUint;
            calculateWinner(instance.entryID, instance.oraclize_gameID);
        }

    }

    //actually, however many people enter will determine wins and losses. 
    //500 people enter. oakland has 4 to 1 odds. 400 should bet on okaload. 100 on den
    function calculateWinner(uint _entryID, bytes32 _gameID) notInMaintenance onlyOraclize onlyInState(_entryID, stateOfEntry.Accepted) internal {

        game hasfinalScores = games[_gameID];
        entryInformation instance = entries[_entryID];
        uint payout = instance.etherSentByUser * 2;


        if (sha3(instance.chooseHomeOrAway) == sha3("H")) { //the sha3 allows comparisons, because as in java, == does not compare the literals of two strings
            if (hasfinalScores.homeScore > hasfinalScores.awayScore) {

                ///dont have a max payout but i would have other stipulations in future

                if (payout > uint(-ledger[contractBalance])) {
                    payout = uint(-ledger[contractBalance]);
                }

                //dont have this. seems they are transfersing money to a payout accountn
                //bookkeeping(acc_Payout, acc_Balance, payout); //they say: cashing out the payment

                //still dont get how ! works 
                if (!instance.user.send(payout)) {
                    instance.state = stateOfEntry.SendingFailure;
                    instance.stateMessage = 'Payout, send failed!';
                    LOG_SendFail(_entryID, 'payout sendfail');
                } else {
                    instance.state = stateOfEntry.Winner;
                    instance.stateMessage = 'Payout successful!';
                    instance.stateTime = now; // won't be reverted in case of errors
                    LOG_entryWinner(_entryID, payout);
                }
            } else {
                instance.state = stateOfEntry.Loser;
                instance.stateMessage = "Your game lost!";
                instance.stateTime = now;
                LOG_entryLoser(_entryID);
            }

        } else {
            if (hasfinalScores.homeScore < hasfinalScores.awayScore) {
                ///dont have a max payout but i would have other stipulations

                if (payout > uint(-ledger[contractBalance])) {
                    payout = uint(-ledger[contractBalance]);
                }

                //dont have this. seems they are transfersing money to a payout accountn
                //bookkeeping(acc_Payout, acc_Balance, payout); //they say: cashing out the payment

                //still dont get how ! works 
                if (!instance.user.send(payout)) {
                    instance.state = stateOfEntry.SendingFailure;
                    instance.stateMessage = 'Payout, send failed!';
                    LOG_SendFail(_entryID, 'payout sendfail');
                } else {
                    instance.state = stateOfEntry.Winner;
                    instance.stateMessage = 'Payout successful!';
                    instance.stateTime = now; // won't be reverted in case of errors
                    LOG_entryWinner(_entryID, payout);
                }
            } else {
                instance.state = stateOfEntry.Loser;
                instance.stateMessage = "Your game lost!";
                instance.stateTime = now;
                LOG_entryLoser(_entryID);
            }

        }
    }

    //fallback function: dont accept ether, except from owner
    function () onlyOwner {
        //put additional funds into error fund
        bookKeeping(contractBalance, errorFund, msg.value);
    }
}//end of contract

