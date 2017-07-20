/*
SINGLE GAME APP

Things I could Add
- declined working
- manual payout working

Things I don't Get
- oraclize proofs
- maintenance, a bit
- mutex - mutual exclusion 
- _ on its own - IT REPRESENTS WHERE THE CODE WILL BE ENTERED
- _variable - CLASS ATTRITUBES HAVE _ IN C++. IN JAVA THOUGH, YOU CAN USE this.variable. summary: underscore means this variable is unique to this function 
- reentry guard - DAO hack - a reentry is an external call to a public function followe by another call to a funciton of the same contract before the first function finished execution

******************************

FULL FOOTBALL PICKEM POOL APP

Things I could Add
- Front end
    dropdown menu so they can't screw up inserting values
- DEN05H - simplest I have now
- could have a decryptor on the front end that shows you what your picks are that goes back and forth
- it would not be TOTALLY private unless we do hash them with the public key. but we could also have the user enter the public key so that he could still decyrpt on his own


Things I don't get
- Seems like getting all 16 games might be best done with 16 different oracle calls. too expensive to parse?


*/


/*Created by David Kajpust - July 2017*/

pragma solidity ^ 0.4.12;


import "./github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "https://raw.githubusercontent.com/Arachnid/solidity-stringutils/master/strings.sol";

contract SingleGameContract is usingOraclize {

    using strings for *; //what is this???????


    /*************************modifiers*********************************/
    modifier noEther {if (msg.value > 0) throw; _ }
    modifier onlyOwner {if (msg.sender != owner) throw; _ }
    modifier onlyOraclize {if (msg.sender != oraclize_cbAddress()) throw; _ }
	modifier onlyInState (uint _entryID, stateOfEntry _state) {
		entryInformation instance = entries[_entryID];
		if (instance.state != _state) throw;
		_;
	}
    modifier notInMaintenance {
        healthCheck();
        if (maintenance_mode >= maintenance_emergency) throw;
    }
    modifier noRentry {
        if (reentryGuard) throw;
        reentryGuard = true;
        _;
        reentryGuard = false;
    }

	/*enums are one way to create a user defined type in Solidity. they are explicitly convertible to and from all integer types, but implicit convestion
	is not allowed. the explicit converstions check the value ranges at runtime and a failure causes an exception. enums need at least one number*/
    enum stateOfentry {Applied, Accepted, Winner, Loser, Declined, SendingFailure } //00 01 02 03 04 05
    enum oraclizeState { GetHome, GetAway } //00 01


    //events
    event LOG_entryApplied (
        uint entryID, //first entry would be 1, 2. links to gameID
        address user, //might be a duplicate variable, if you bet on two diff games
        string homeOrAway, //H or A
    );
    event LOG_entryAccepted(
        uint entryID,
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
        bytes32 reason
    );
    event LOG_entryManualPayout( //will need to add later
        uint entryID,
        bytes32 reason
        //does this need uint amount? it doesnt in the other policy 
    );
    event LOG_SendFail(
        uint entryID,
        bytes32 reason
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
    uint8 constant maintenance_None = 0
    uint8 constant maintenance_BalTooHigh = 1;
    uint8 constant maintenance_Emergency = 255;

    //api strings, hardcoded with a specific date
    string constant oracalizeOneGameApiStart = "[URL] json(http://api.sportradar.us/nfl-ot1/games/";
    string constant oracalizeOneGameApiHome = "/boxscore.json?api_key=4dm7ds2degn9av2yp9ayqgtz).summary.home.points";
    string constant oracalizeOneGameApiAway = "/boxscore.json?api_key=4dm7ds2degn9av2yp9ayqgtz).summary.away.points";

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
        stateOfentry state;
        // 7 - time of last state change
        uint stateTime;
        // 8 - state change message/reason
        bytes32 stateMessage;
        // 9 - TLSNotary Proof from oraclize
        bytes proof;
    }

    //has the information about the game itself, and the results, which is enough information to determine winner or loser. 
    struct game {

        //the tag that allows for a specific game to be called. will need to be gathered from front end somehow. for testing in truffle it will be written in test
        bytes32 gameAPITag;
        //receive the score from oracle and saved. home score is called first, then away gets called right after, in a callback function
        uint8 homeScore;
        //receive from oracle and saved
        uint8 awayScore;

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
    mapping(uint8 => game) public games;

    //Internal ledger
    int[5] public ledger;

    //Mutex
    bool public reentryGuard;
    uint8 public maintenance_mode;


/***************************************************************************FUNCTIONS**********************************************************************************/

    function healthCheckContract() internal {
        int diff = int(this.balance - msg.value) + ledger[contractBalance]
        if (diff == 0) {
            return; // the amount being paid out and the contract amount are equal. nothing wrong with contract
        }
        if (diff > 0) {
            LOG_HealthCheck('Balance is too high', diff, this.balance, ledger[contractBalance]);
            maintenance_mode = maintenance_BalTooHigh;
        } else {
            LOG_HealthCheck('Balance too low', diff, this.balance, ledger[contractBalance]);
            maintenance_mode = maintenance_emergency;
        }
    }



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

        bookkeeping(_from, _to, _amount);

    }

    function getentryCount(address _user) constant returns (uint _count) {
        return entries.length;

        function getentryGameCount(address _user) constant returns (uint _count) { //i guess the plane one sees how many entries one use has. this would see how many weeks one user has?
            return entryIDs[_user].length
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
        function FootballDapp() {
            owner = msg.sender;
            reentryGuard = false;
            maintenance_mode = maintenance_None;

            //initialze the contract by putting in the start that I want to have for an error fund for backup
            bookkeeping(contractBalance, errorFund, msg.value);
            oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS); //need to read oraclize contract to dig into this
        }

        //
        function newEntry(string  _gameTagFromApi, string _homeOrAway, uint _startTimeOfGame) notInMaintenance {
		
            uint _testingAugust2016 = 1470614400; //testing phase, to work with old games, the current games dont exist
            uint _startOf2017Season = 1501702200; //august 2nd, 730pm 2017
            uint _endOf2017Season = 1514808000; //january 1st, noon, 2018


            //this logic is you are not allowed to enter
            if (msg.value !== 100 finney) {
                LOG_entryDeclined(0, 'All entries must bet 0.1 ether');
                if (!msg.sender.send(msg.value)) {
                    LOG_SendFail(0, 'newEntry sending of EtherFailed (1)');
                }
                return;
            }

            if (_startTimeOfGame > now + 1 hours || _startTimeOfGame < _testingAugust2016 || _startTimeOfGame > _endOf2017Season){
                LOG_entryDeclined(0, 'Must be 2017 season and at least 1 hour before 1st game of week');
                if (!msg.send.send(msg.value)) {
                    LOG_SendFail(0, 'newEntry sendback failed (2)');
                }
                return;
            }

            //c8dc876a-099e-4e95-93dc-0eb143c6954f the tag

            bytes32  gameID = _gameTagFromApi
            game gameMapping = games[gameID];


            //where entries is a struct with ~5 values 
            uint entryID = entries.length++;//figure out entryID number based on previous ones that exist
            entryIDs[msg.sender].push(entryID); //where entryIDs is a mapping of addresses to entryIDS for loookup
            entryInformation instance = entries[entryID];

            instance.user = msg.sender;
            instance.etherSentByUser = getOperatingCostsAndRemainingPool();
            instance.gameID = gameID;
            instance.chooseHomeOrAway = _homeOrAway;

            instance.state = stateOfentry.Applied;
            instance.stateMessage = "Game bet applied successfully by entry";
            instance.stateTime = now;
            LOG_entryApplied(entryID, msg.sender, _homeOrAway) //do i need to add weekly games to here

            //now youve entered, but we gotta see if you string is okay, then log entryAccepted
            acceptUserEntry(entryID);

        }

        /*it will already have the policy/week uploaded
        
        they need to get user entry, use oracle to get flight stats, then underwrite or payout
        which is where they check the results, and they might decline. if its a payout they call o
        oracle, , see if it worked, then run through payout
        
        i need to get user entires. check if week is uploaded. upload if it isnt
        check if user entry is correct. then upload to EVM
        
        then i need to keep doing that until time is triggered. i then i pull game data
        check who won. pay them out. download and open new week
        */

        /* decline will BE ADDED IN AFTER. I wanna get the app to work before I try this
        function decline() {

        }
        */
        //underwrite
        //this is acutally putOnEVM. i do not use oracle here

        function acceptUserEntry(uint _entryID) { //_entryID here is used to get all information from the entryID, so i dont have to pass a ton of data to here
            entryInformation instance = entries[_entryID]


            checkOneHomeGame(_entryID, instance.gameID);
            //putOnEVM();

            //logic to check if the actual entry is valid. this is not part of MVP so later
            // 

            LOG_entryAccepted(
                _entryID
            );



        }


        //week of payout is similar to policyID
        function checkOneHomeGame(uint _entryID, bytes32 _gameID) {

            string memory oraclize_url_home = strConcat(oracalizeOneGameApiStart, _gameID, oracalizeOneGameApiHome);
            bytes32 queryId = oraclize_query("nested", oraclize_url_home, oraclizeGas);

            //dont get the negative here
            bookKeeping(oracalizeFeesFund, contractBalance, uint((-ledger[contractBalance]) - int(this.balance)));
            oraclizeCallbacks[queryId] = oraclizeCallback(_entryID, oraclizeState.GetHome, _oraclizeTime, _gameID);


            LOG_OraclizeCall(_entryID, queryID, oraclize_url_home);
        }

        function checkOneAwayGame(bytes32 _entryID, bytes32 _gameID) {

            string memory oraclize_url_away = strConcat(oracalizeOneGameApiStart, gameID, oracalizeOneGameApiAway);
            bytes32 queryId = oraclize_query("nested", oraclize_url_away, oraclizeGas);

            //dont get the negative here
            bookKeeping(oracalizeFeesFund, contractBalance, uint((-ledger[contractBalance]) - int(this.balance)));
            oraclizeCallbacks[queryId] = oraclizeCallback(_entryID, oraclizeState.GetAway, _oraclizeTime);

            LOG_OraclizeCall(_entryID, queryID, oraclize_url_away);
        }



    }

    function __callBack(bytes32 _queryId, string _result, bytes _proof) onlyOraclize noRentry{
        //	make sure the games are what we want, then call pullFromEVM

        //dont use a counter. use oraclzie state 
        oraclizeCallback memory instance = oralcizeCallbacks[_queryId];




		/* i have the query ID, which two are linked to a single entry ID,
		 which has a game chosen and home or away, 
		 which is linked to the struct game, which has weather H or A won,
		 which is gathered from the oracle calls, and their results.
		 
		 queryID && result ---> entryID ---> HorW && Struct Game ---> Scores/Winner


		 you can look up struct oraclizeCallbacks to get entryID from QueryID
		 you can look up the game struct with gameID in entry ID
		  */


        LOG_OraclizeCallback(instance.entryID, _queryId, _result, _proof); //weekOfBetting from week struct , part of oraclized callbacks mapping

        if (instance.oState == oraclizeState.ForHome) {
            game saveHomeScoreInstance = games[instance.oraclize_gameID];
            saveHomeScoreInstance.homeScore = _result;
            checkOneAwayGame(instance.entryID, instance.oraclize_gameID);
        } else {
            game saveAwayScoreInstance = games[instance.oraclize_gameID];
            saveAwayScoreInstance.awayScore = _result;
            calculateWinner(instance.entryID, instance.oraclize_gameID);
        }


        //4dm7ds2degn9av2yp9ayqgtz
        //parse the data from EVM.
        //if you typed in the wrong value, your fault you dont get paid back for now. ie. dont worry about string length
        //add up scores of each guy
        //go to payout 
        // https://github.com/Arachnid/solidity-stringutils
        /*THIS IS GOING TO BE FUCKING HARD! BUT I CAN DO IT!. i am a solidity prodigy */

        //do i need anohter state of entry for applied? I think i might, our buddies did 
        function calculateWinner(bytes32 _entryID, bytes32 _gameID) notInMaintenance onlyOraclize onlyInState(_entryID, stateOfentry.Accepted) internal {

            game hasfinalScores = games[_gameid];
            entryInformation instance = entries[_entryID]

            //just realized you only pick H or A. It is calculating a 50/50 win right now.
            //actually, however many people enter will determine wins and losses. 
            //500 people enter. oakland has 4 to 1 odds. 400 should bet on okaload. 100 on den
            // YEP. just gotta do some averages :) 
            //OKAY I WILL DO THIS AFTERWORDs. FOR NOW JUST PAYOUT 1 GUY. I NEED TO GET THIS GOING

            if (instance.chooseHomeOrAway === "H") {
                if (hasfinalScores.homeScore > hasfinalScores.awayScore) {
                    uint payout = instance.etherSentByUser * 2;

                    ///dont have a max payout but i would have other stipulations

                    if (payout > uint(-ledger[contractBalance])) {
                        payout = uint(-ledger[contractBalance]);
                    }

                    //dont have this. seems they are transfersing money to a payout accountn
                    //		bookkeeping(acc_Payout, acc_Balance, payout);      // cash out payout

                    //still dont get how ! works 
                    if (!instance.user.send(payout)) {
                        instance.state = stateOfEntry.SendingFailed;
                        instance.stateMessage = 'Payout, send failed!';
                        instance.actualPayout = 0;
                        LOG_SendFail(_policyId, 'payout sendfail');
                    } else {
                        instance.state = stateOfEntry.Winner;
                        instance.stateMessage = 'Payout successful!';
                        instance.stateTime = now; // won't be reverted in case of errors
                        LOG_PolicyPaidOut(_entryID, payout);
                    }
                } else {
                    instance.state = stateOfEntry.Loser;
                    instance.stateMessage = "Your game lost!";
                    instance.stateTime = now;
                    LOG_Policy_entryLoser(_entryID);
                }

            } else {
                if (hasfinalScores.homeScore < hasfinalScores.awayScore) {

                    uint payout = instance.etherSentByUser * 2;

                    ///dont have a max payout but i would have other stipulations

                    if (payout > uint(-ledger[contractBalance])) {
                        payout = uint(-ledger[contractBalance]);
                    }

                    //dont have this. seems they are transfersing money to a payout accountn
                    //		bookkeeping(acc_Payout, acc_Balance, payout);      // cash out payout

                    //still dont get how ! works 
                    if (!instance.user.send(payout)) {
                        instance.state = stateOfEntry.SendingFailed;
                        instance.stateMessage = 'Payout, send failed!';
                        instance.actualPayout = 0;
                        LOG_SendFail(_policyId, 'payout sendfail');
                    } else {
                        instance.state = stateOfEntry.Winner;
                        instance.stateMessage = 'Payout successful!';
                        instance.stateTime = now; // won't be reverted in case of errors
                        LOG_PolicyPaidOut(_entryID, payout);
                    }
                } else {
                    instance.state = stateOfEntry.Loser;
                    instance.stateMessage = "Your game lost!";
                    instance.stateTime = now;
                    LOG_Policy_entryLoser(_entryID);
                }

            }
        }


        //fallback function: dont accept ether, except from owner
        function () onlyOwner {
            //put additional funds into error fund
            bookkeeping(contractBalance, errorFund, msg.value)
        }






    }


/*

workflow of flight app
-newpolicy
	getFlightStats - which uses oracle. and then 
		__Callback - which will decide to call either underwrite or Payout
			callback_ForUnderwriting - which does the neat calcs and parsing strings
				underwrite - called when all is working. and it finalizes all data on the users end and his poilcy esists
					schedulePayoutOraclizeCall - does some oraclize calls. uses struct oraclizeCallback. might do oracle callback
						END
			callback_ForPayout
				ERROR - schedulePayoutOraclizeCall - will look to schedulePayoutOracalizecall if there is problem. might do a callback
				does some nice parsing, then calls payout. 
				also will let you do LOG_PolicyManualPayout
					payout - will just do some calcs and then payout the dude who wins
						END


my functions (5, and declined, so 6)

confirmUserEntry (underwrite)
	putOnEVM (schedulePayoutOraclize)
checkWinner (getFlightStats)
	__callback
	pullFromEVM (schedulePayoutOraclize)
	calculateWinner (payout split in 2)
	payout (payout split in two)

removed
	callback_forUnderwriting
	callback_forPayout


workflow for MY APP 
-newentry
	comfirmUserEntry - confirms the user Entry is good to go ===UNDERWRITE
o		uploadToIFPS - once users entry is good, call IFPS and upload to there === SCEHDULEPAUOUTORACLIZE
			dont use callback. leave it there till it is triggered by time.

-checkWinner (based on time)
o	confirmWeekIsOver - confirm no errors in week, uses oracle to go get results from game ===GET FLIGHT STATS
o		__callback ????
o			pullFromEVM - all results are in, so go get the user entries ===SIMILAR TO SCHEDULEPAYOUTORACLE. but we pulling data yo!
				calculateWinner - take all results, parse em into numbers that are related to the account
				ERROR checking. manual payout
					payout - take the highest number and make him a winner





i need to think, how often do I need to make oracle calls???????
i need to think when do I need things on the blockchain? and when do i need them off the blockchain
	1. definetly need to get oracle to call for the game results
	2. I do not want to hardcode in oracle games , as the last few weeks can change 
		quickly or be TBD. so tuesdays or wednesdays, oracle should call for the 
		games. but, then i want user to be able to enter games whenever. 
			.....yeah this is front end stuff. i can change to accomodate. only release the entry based on day i decide. so the games themselves should be hardcoded. but front end should let me change how people can enter and when
		and it only depedns on thursday start and monday end. so maybe its okay
	3. i believe i want the oracle to upload the user bet to IPFS. i do not want 
		to store that data on a server. this dApp is backend-less ... i think
	4.oracle then needs to call off all the of the values from IPFS and give 
		back to smartContract to add up scores and see who won. 
		highest score gets paid out

	so in summary. pull game results. post on ipfs. pull from ipfs
	the other has pull risk, post on ipfs. pull flight result, pull ifps. i have one less step in risk 
	

	how does winning logic look. oracle needs to grab the 16 games and have Home and away. it will
		parse the string, and maybe go HOMETEAMTAG05H. so denver home vs seattle, pick denver to
		 win is DEN05H. seattle is DEN05S. YES!... but needs updating based on what API i use
		 it also needs to show all users entries at the end, so that people know they legitimately won. front end thou



/*how do I want to set up betting on the WEEKS and YEARS	
	I should just forsure not hardcode it.
	each week is a policy you can enter on in each year
	the smart contract gets the next week one week ahead. it makes a new "policy"
	the entries can then enter on that week
	which means i will have to close down and open up an old one and a new one on the same function
	which means now i will have 4 steps.

o		(initiation) pull so we have one weeks. make sure string length correct for games
		post users entries on EVM
o		pull game results. 
		pull from EVM and confirm winner and payour
o		pull new week, open it to entry
		repeat

		each new week will have 10-16 games, so strings will be different

in flight one, there is a pool of possibile policiea (very large)
	a customer can make 3 or 4 or 1 polciies. that individual one gets approved
	each policyID holds the customer, and the choices  they made
	determine if you win or lose from outside results. many diff policies can win


in football app, there is a pool of possible weeks to play (smaller)
	a customer can make 1 or 2 or 3 entries in one week, or multi weeks
	each entryID should hold the customer address, and the choices they made.
	which would be the week as well as the string chosen


week 01 //chosenWeek
	entry 01 //choosen String
		address 0x
		string DEN05H
	entry 02
	entry 03
week 02
	entry 01
	entry 02
	entry 03

only one week at a time can be bet on. 
this way i can have every entry be calculated in correct order and not mixed
weeks will take on same view as risk. cuz its an outside variable changing payout
and it doesnt make WEEK super important. week just is one thing that can be won. the
results are seperate from the entry. entry is how you get paid out. it checks if your
entry won based on results from risk. one person gets paid. end. 









GAMES
.fullgameschedule
{

	fullgameschedule: {
		lastUpdatedOn: "2017-07-10 10:43:36 AM",
		gameentry: [
		{
			id: "35171",
			week: "1",
			date: "2016-09-08",
			time: "8:30PM",
			awayTeam: {
				ID: "69",
				City: "Carolina",
				Name: "Panthers",
				Abbreviation: "CAR"
			},
			homeTeam: {
				ID: "72",
				City: "Denver",
				Name: "Broncos",
				Abbreviation: "DEN"
			},
			location: "Sports Authority Field"
	},
}




*/
