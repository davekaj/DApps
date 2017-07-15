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
- how does reentrant guard work and what does it do? i know i can find this on the internet


*/

/*Created by David Kajpust - July 2017*/

pragma solidity ^0.4.12;


import "./github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "./github.com/Arachnid/solidity-stringutils/strings.sol";

contract FootballPickemContract is usingOraclize {

	//modifiers

	modifier noEther {if (msg.value > 0) throw; _ }
	modifier onlyOwner {if (msg.sender != owner) throw; _}
	modifier onlyOraclize {if (msg.sender != oraclize_cbAddress()) throw; _ }

	//onlyinstate, onlycustomer,

	modifier notInMaintenance {
		healthCheck();
		if (maintenance_mode >= maintenance_emergency) throw;
	}

	modifier noRentract {
		if (reentrantGuard) throw;
		reentrantGuard = true;
		_
		reentrantGuard = false;
	}

	//enums
	/*enums are one way to create a user defined type in Solidity. they are explicitly convertible to and from all integer types, but implicit convestion
	is not allowed. the explicit converstions check the value ranges at runtime and a failure causes an exception. enums need at least one number*/


	// state of entrant Codes and meaning:
	//
	// 00 = Applied:	the entrant has payed a premium, but the oracle has
	//					not yet checked and confirmed.
	// 01 = Accepted:	the oracle has checked and confirmed. // i dont think this is happening. i am just posting something to ipfs, maybe oracale does it, maybe not

	// 02 = Winner:		Their 16 games are the best choice of all. only one entrant gets this
	//					The oracle has checked and payed out.
	// 03 = Loser:		Every other person is a loser
	//					No payout.
	// 04 = Declined:	The application was invalid. (UX/UI SHOULD BE DESIGNED TO REALLY PREVENT THIS)
	//					The bet minus cancellation fee is payed back to the
	//					customer by the oracle.
	// 05 = SendFailed:	During Revoke, Decline or Payout, sending ether failed XXXXXXXXXX not sure how this works
	//					for unknown reasons.
	//					The funds remain in the contracts RiskFund.


	enum stateOfEntrant { //these cab be labelled 00, 01, 02, 03, 04, 05, 06..... but do I need to do this?
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
		CheckGamesForPayout}
	//events

	event LOG_EntrantApplied (
		uint entrantID, //first entrant would be 1, 2, etc.
		address entrant, //might be a duplicate vairalbe
		string consolidatedBets, //this i want to be one long string that can be decrypted into the answer
		//dont think i need the bet here, as all bets will be same. unless I have three differnt 
	);

	event LOG_EntrantAccepted(
		uint entrantID,
		//uint statistics?

	);
	event LOG_EntrantWinner(
		uint entrantID,
		uint amount
	);
	event LOG_EntrantLoser(
		uint entrantID
	);
	event LOG_EntrantDeclined(
		uint entrantID,
		bytes32 reason
	);
	//this is only if I have to go back and fix it. also maybe add on to later? 
	event LOG_EntrantManualPayout(
		uint entrantID,
		bytes32 reason
		//does this need uint amount? it doesnt in the other policy 
	);
	event LOG_SendFail(
		uint entrantID,
		bytes32 reason
	);


	//oraclize events
	event LOG_OraclizeCall(
		uint entrantID,
		bytes32 queryId,//used to interact with oracle
		string oraclize_url
	);
	event LOG_OraclizeCallback(
		uint entrantID,
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

	uint8 constant minimumEntrants = 2;



//accounting numbers
	uint totalEntrants;

	uint totalPayout = totalEntrants*betInEther;
	uint contractBalance; //do i need both of these?


	uint8 constant feesForOraclize = 5; //cents? i dont know

	uint8 constant feesForUpdatingApp = 1; //1%

	uint8 constant feesForErrors = 1; //1%, for if anyting evey goes wrong, there is money on reserve

	//gas constant for oraclize. set at 500000 for now, might be changed
	uint constant oraclizeGas = 500000;

//maintenance modes
	//will need some sort of indicator for maintenance, I think....
	uint constant maintenance;


//urls and query strings for oraclize
	//for getting the game results
	string constant oracalizeGamesURL = "[URL] json(http://api.nfl.com)";
	//guess you wouldnt really have to encrypt this data across the internet....
	string constant oraclizeGamesQueryEncrypted = "?${[decrypt] AFDSGDFDSGFSDFSDGSDGSDG and some other shit}"
	//entrant result. note that there will be multiple of these? or multiple calls into the contract. i don't know exactly how i am going to show that right now
	string constant entrantsResults = "some results that are entered from the front end of the app. these need to be sent to oraclize, and then most likely stored on IPFS in a SAFE PLACE and encrypted so that no one knows what is uploaded. it should also be one line of text that gets decypted and solved. needs minimum storage"
	//encrypted entrant result
	string constant encryptEntrantResults;


	//

	struct entrant_Information {
		//unique public addresss of entrant
		address entrant;
		//this should be a constant between each one
		uint amountWagered;
		//this will be based on how many people enter. really it can't be calculated until the first game is played. so it might not be in here at all. as there will be one state which pays out the whole policy
	//	uint amountPayedOut

		//status fields:
		stateOfEntrant state;
		// 7 - time of last state change
		uint stateTime;
		// 8 - state change message/reason
		bytes32 stateMessage;
		// 9 - TLSNotary Proof
		bytes proof;
	}

	//i cant think of any sceanario where i need another struct right now. but here for thought
	struct risk {}
	//hmmmmmm maybe this will be each weeks uploaded data. which could be grabbed based on time. or it could be uploaded by hand each week. BUT somehow the
	//oracle needs to know each week is a different 'structure' of games in order. the other option is having all 16 games made BEFOREHAND. 
	// then make a new contract next year when scheudle is out?


	struct oraclizeCallback {

		// for which entrant have we called?
		uint entrantID;
		// for which purpose did we call? {ForUploadData | ForPayout}
		oraclizeState oState;
		uint oraclizeTime;

	}

//other variables, the ones that are interactive with the contract, based on how many people enter
	address public owner; // guy who publishes contract (me)

	//table of everyone who has entered
	entrant_Information[] public entrants;
	//lookup entrantIDs from entrant public addresses
	mapping (address => uint[]) public entrantIds;
	//lookup entrantIDs from queryIDs
	mapping (byes32 => oraclizeCallback) public oraclizeCallbacks;
	mapping (bytes32 => risk) public risk // this would be the weekly games if i decided to do it this way
	//Internal ledger
	int[6] public ledger;

	//Mutex
	bool public reentrantGuard;
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

	}

	function bookKeeping() internal {

	}

	//if ledger somehow gets corrected, have a way to fix it. I DONT THINK I NEED THIS. my ledger is simple, .1 eth, each account
	function audit() onlyOwner {

	}

	function getEntrantCount(address _entrant) constant returns (uint _count) {
		return entrants.length;

	function getEntrantWeeklyCount(address _entrant) constant returns (uint _count) { //i guess the plane one sees how many entries one use has. this would see how many weeks one user has?
		return entrantIDs[_entrant].length
	}















}
