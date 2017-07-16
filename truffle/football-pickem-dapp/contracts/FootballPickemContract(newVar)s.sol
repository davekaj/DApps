/*
things i could add 
- could have a decryptor on the front end that shows you what your picks are that goes back and forth
- it would not be TOTALLY private unless we do hash them with the public key. but we could also have the user enter the public key so that he could still decyrpt on his own
- the above seems like an extra thing to add, get the MVP first


things i am not sure about
- maybe i might end up having them actually uploading a string of numbers, seperated by sapces. "1 15 24 7 4 3 5" etc. no hiding. that could also be my MVP
- how the oracalized proof works
- how the maintenance stuff works
- how will i upload the games? all at once already? 16 different games you can enter? this has to do with the risk stsruct
- wtf is mutex and how do i use it
- so an _ in front of a varialbe is distiigushing local function variables from global variables
- how does reentry guard work and what does it do? i know i can find this on the internet


*/

	/*what would be the easiest way to transmit user information? 
	need to have a dropdown menu, with options 1-16 so the user cants screw it up
	01-16 actually so i can split it up at intervals of 2
	then i could sha3 it with the users account name and the sting of 
	010405130406 etc etc. so overall the front end will take all of those numbers*/



/*Created by David Kajpust - July 2017*/

pragma solidity ^0.4.12;


import "./github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "./github.com/Arachnid/solidity-stringutils/strings.sol";

contract FootballPickemContract is usingOraclize {

	using strings for *; //what is this???????


	//modifiers

	modifier noEther {if (msg.value > 0) throw; _ }
	modifier onlyOwner {if (msg.sender != owner) throw; _}
	modifier onlyOraclize {if (msg.sender != oraclize_cbAddress()) throw; _ }

	//onlyinstate, onlycustomer,

	modifier notInMaintenance {
		healthCheck();
		if (maintenance_mode >= maintenance_emergency) throw;
	}

	modifier noRentrt {
		if (reentryGuard) throw;
		reentryGuard = true;
		_
		reentryGuard = false;
	}

	//enums
	/*enums are one way to create a user defined type in Solidity. they are explicitly convertible to and from all integer types, but implicit convestion
	is not allowed. the explicit converstions check the value ranges at runtime and a failure causes an exception. enums need at least one number*/


	// state of entry Codes and meaning:
	//
	// 00 = Applied:	the entry has payed a premium, but the oracle has
	//					not yet checked and confirmed.
	// 01 = Accepted:	the oracle has checked and confirmed. // i dont think this is happening. i am just posting something to ipfs, maybe oracale does it, maybe not

	// 02 = Winner:		Their 16 games are the best choice of all. only one entry gets this
	//					The oracle has checked and payed out.
	// 03 = Loser:		Every other person is a loser
	//					No payout.
	// 04 = Declined:	The application was invalid. (UX/UI SHOULD BE DESIGNED TO REALLY PREVENT THIS)
	//					The bet minus cancellation fee is payed back to the
	//					customer by the oracle.
	// 05 = SendFailed:	During Revoke, Decline or Payout, sending ether failed XXXXXXXXXX not sure how this works
	//					for unknown reasons.
	//					The funds remain in the contracts RiskFund.


	enum stateOfentry { //these cab be labelled 00, 01, 02, 03, 04, 05, 06..... but do I need to do this?
		Applied, 
		Accepted,
		Winner,
		Loser, 
		Declined,
		SendingFailure
	}

	//  secure an entry and call the oracle to place it in IPFS (is this what it acutally does lol? maybe note), and check games for payout monday night at 1am
	enum oraclizeState {
		SecureAnEntry, 
		//getAllEntries?? ....need?
		CheckGamesForPayout}
	//events

	event LOG_entryApplied (
		//entryID has week information too
		uint entryID, //first entry would be 1, 2. 
		address user, //might be a duplicate vairalbe
		string consolidatedBets, //this i want to be one long string that can be decrypted into the answer
		//dont think i need the bet here, as all bets will be same. unless I have three differnt 
	);

	event LOG_entryAccepted(
		uint entryID,
		//uint statistics?

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
	//this is only if I have to go back and fix it. also maybe add on to later? 
	event LOG_entryManualPayout(
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
		string result, //what the oracle brings back. should be results of all games, winners and total losers
		bytes proof //the proof thing which i dont undertand fully
	);

	//this is there to check if the amount of ether in the contract acutally lines up with what the payout is. 
	event LOG_HealthCheck(
		bytes32 message, 
		int diff,
		uint balance,
		int ledgerBalance 
	);


	/******************Constants*********************/
//general constants for the whole contract
	uint constant betInEther = 0.1 ether; // should be like, 100 finney actually
	//date that the contract ends. question for myself. Do i need to post a new contract each week? or can I have updated one ....
	//note that if I had exactly one each week, new, i would have to be explicit and make sure people dont fuck up and send money elsewhere
	uint contractDeadline;

//might need to have a condition where if one person enters they dont lose any money
	uint8 constant minimumEntries = 2;


	//gas constant for oraclize. set at 500000 for now, might be changed
	uint constant oraclizeGas = 500000;


	uint8 constant percentFeeForDapp = 1; //1%

	uint8 constant percentFeeForErrors = 1; //1%, for if anyting evey goes wrong, there is money on reserve

//accounting numbers
	uint totalEntries;

	//uint totalPayout = totalentrys*betInEther; dont think i need this


// account numbers for the internal ledger
	//sum of all entry fees from users. will be a multiple of entrys entered
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
	//will need some sort of indicator for maintenance, I think....
	uint8 constant maintenance_None = 0
	uint8 constant maintenance_BalTooHigh = 1;
	uint8 constant maintenance_Emergency = 255;


//urls and query strings for oraclize
	//for getting the game results
	string constant oracalizeGamesURL = "[URL] json(http://api.nfl.com)";
	//guess you wouldnt really have to encrypt this data across the internet....
	string constant oraclizeGamesQueryEncrypted = "?${[decrypt] AFDSGDFDSGFSDFSDGSDGSDG and some other shit}"
	//entry result. note that there will be multiple of these? or multiple calls into the contract. i don't know exactly how i am going to show that right now
	string constant entrysResults = "some results that are entered from the front end of the app. these need to be sent to oraclize, and then most likely stored on IPFS in a SAFE PLACE and encrypted so that no one knows what is uploaded. it should also be one line of text that gets decypted and solved. needs minimum storage"
	//encrypted entry result
	string constant encryptentryResults;


	//

	struct entry_Information {
		//unique public addresss of entry
		address user;
		//this should be a constant between each one
		//uint amountWagered; nope, this is msg.value
		//this will be based on how many people enter. really it can't be calculated until the first game is played. so it might not be in here at all. as there will be one state which pays out the whole policy
	//	uint amountPayedOut

		string combinedStringOfUserEntries; // 01 05 14 13 etc. 

		//pointer to the week that is needed
		bytes32 weekID;
		//status fields:
		stateOfentry state;
		// 7 - time of last state change
		uint stateTime;
		// 8 - state change message/reason
		bytes32 stateMessage;
		// 9 - TLSNotary Proof
		bytes proof;
	}

	struct week {

		uint numberOfGames;
		uint lengthOfString;
		string userChoicesString;
		uint weekOfBetting;
		//counter????
	}



	struct oraclizeCallback {

		// for which entry have we called?
		uint entryID;
		// for which purpose did we call? {ForUploadData | ForPayout}
		oraclizeState oState;
		uint oraclizeTime;

	}

//other variables, the ones that are interactive with the contract, based on how many people enter
	address public owner; // guy who publishes contract (me)

	//table of everyone who has entered
	entry_Information[] public entrys;
	//lookup entryIDs from entry public addresses
	mapping (address => uint[]) public entryIDs;
	//lookup entryIDs from queryIDs
	mapping (byes32 => oraclizeCallback) public oraclizeCallbacks;
	mapping (bytes32 => risk) public risk // this would be the weekly games if i decided to do it this way
	//Internal ledger
	int[5] public ledger;

	//Mutex
	bool public reentryGuard;
	uint8 public maintenance_mode;

	function healthCheckContract() internal {
		int diff = int(this.balance-msg.value) + ledger[contractBalance]
		if (diff == 0){
			return; // the amount being paid out and the contract amount are equal. nothing wrong with contract
		}
		if (diff > 0){
			LOG_HealthCheck('Balance is too high', diff, this.balance, ledger[contractBalance]);
			maintenance_mode = maintenance_BalTooHigh;
		} else {
			LOG_HealthCheck('Balance too low, diff, this.balance, ledger[contractBalance]);
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

		bookkeeping (_from, _to, _amount);

	}

	function getentryCount(address _user) constant returns (uint _count) {
		return entrys.length;

	function getentryWeeklyCount(address _user) constant returns (uint _count) { //i guess the plane one sees how many entries one use has. this would see how many weeks one user has?
		return entryIDs[_user].length
	}


//the problem is for this each preimum is unique. mine is a whole pool. so it will have to be used differently
	function getOperatingCostsAndRemainingPool() internal returns (uint) {

		uint entryFee = msg.value;
		uint updateDappFee = entryFee*percentFeeForDapp / 100;
		uint errorFee = entryFee*percentFeeForErrors / 100;


		bookKeeping(contractBalance, poolFund, entryFee);
		bookKeeping(poolFund, updatingDappFund, updateDappFee);
		bookKeeping(poolFund, errorFund, errorFee);

		return (uint(entryFee - updateDappFee - errorFee));

	}

	//constructor
	function FootballDapp () {
		owner = msg.sender;
		reentryGuard = false;
		maintenance_mode = maintenance_None;

		//initialze the contract by putting in the start that I want to have for an error fund for backup
		bookkeeping(contractBalance, errorFund, msg.value);
		oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS); //need to read oraclize contract to dig into this
	}


	function newentry(string  _combinedUserGameChoices, string _weekOfGames, uint _startfirstGameOfWeek, uint _endOfLastGameOfWeek) notInMaintenance {

		if (msg.value !== 0.1) {
			LOG_entryDeclined(0, 'All entrys must bet 0.1 ether');
			if (!msg.sender.send(msg.value)){
				LOG_SendFail(0, 'newentry sending of EtherFailed (1)');
			}
			return;
		}

		if (_startfirstGameOfWeek > now + 1 hours{
			LOG_entryDeclined(0, 'You must enter one hour before the start of the first game of the week');
			if (!msg.send.send(msg.value)) {
				LOG_SendFail(0, 'newPolicy sendback failed (3)');
			}
			return; 
		}

		//where entrys is a struct with ~5 values 
		uint entryID = entrys.length++;//figure out entryID number based on previous ones that exist
		entryIDs[msg.sender].push(entryID); //where entryIDs is a mapping of addresses to entryIDS for loookup
		entry_Information instance = entrys[entryID];

		instance.entry = msg.sender;
		instance.splitentryFee = getOperatingCostsAndRemainingPool();

		instance.state = stateOfentry.Applied;
		instance.stateMessage = "Weekly bet applied successfully by entry";
		instance.stateTime = now;
		LOG_entryApplied(entryID, msg.sender, _combinedUserGameChoices) //do i need to add weekly games to here

		acceptUserEntry();

	}


	function decline () {

	}

	//underwrite
	//takes the user entry from the from end, tries to prove that it is correct. if so, it goes to uploadToIPFS
	function acceptUserEntry(uint _entryID, bytes _proof) {


		uploadToIPFS();


		LOG_entryAccepted();



	}

	//o
	//schedulePayoutOraclize
	//this calls oraclize to upload to IPFS. 
	function uploadToIPFS () {

		bytes32 queryID = oraclize_query(_oraclizeTime, 'nested', oraclize_url, oraclizeGas);
		bookkeeping();
		oraclizeCallbacks[queryId] = oraclizeCallback()
	}

	//o
	//getFlightStats
	//uses oraclize to call out to a football API. 
	function checkGames () {

	}

	//o
	//same same
	// this __callback only used after checkGames. needs to make sure all games were properly
	//completed. if so, we go and let oraclize call IPFS to get users entries, and give them
	//to the smart contract 
	function __callBack () {

	}

	//o
	//schedulePayoutOraclize
	//pulls data from IPFS. calls calculate winner
	function pullFromIPFS () {

	}

	//payout / 2
	//make sure our data from IPFS is good. we then go ahead and calculate the points earned for each account
	//most points wins, and we must call payout with that address/entryID
	function calculateWinner () {

	}

	//payout / 2
	//most of calculating done in calculateWinner. this is just to seperate the functions
	function payout () {

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
	uploadtoIPFS (schedulePayoutOraclize)
checkWinner (getFlightStats)
	__callback
	pullFromIPFS (schedulePayoutOraclize)
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
o			pullFromIPFS - all results are in, so go get the user entries ===SIMILAR TO SCHEDULEPAYOUTORACLE. but we pulling data yo!
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
	the entrys can then enter on that week
	which means i will have to close down and open up an old one and a new one on the same function
	which means now i will have 4 steps.

		(initiation) pull so we have two weeks
		post users entries on ifps
		pull game results. 
		oull from ipfs and confirm winner and payour
		pull new week, open it to entry
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



*/

*/