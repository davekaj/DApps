pragma solidity ^0.4.13;

contract SinglePatreon {
    
/*********************************************STATE VARIABLES***************************************************************************/

    address public creator;
    address public owner;
    bytes32 public name; //contract name 
    uint public singleDonationAmount;
    uint public monthlyDonationAmount;
    uint public contractBalance = this.balance;

    uint public contractNumber;
    uint dynamicFirstOfMonth = 1498867200; //starts on July 1st, 2017. JUST REMOVED THIS FROM function and made state variable. This should fix problem of creator doing unlimited withdrawals
    uint8 monthlyCounter = 6; //because we are starting on aug 2017, and its 7th spot in a 12 spot array ************CHANGED TO 6 for TEST
    uint32 public numberOfSingleContributions;
    uint64 leapYearCounter = 1583020800; //did not add an assert for this, as it can't be changed easily
    
    //maintenance modes 
    uint8 constant maintenanceNone = 0;
    uint8 constant maintenance_BalTooHigh = 1;
    uint8 constant maintenance_Emergency = 255;
    uint8 public maintenance_mode;

    bool speedBumpBool = true;
    uint speedBumpTime;
    
    struct donationData {
        address donator;
        uint totalDonationStart;
        uint totalRemaining;
        uint8 monthsRemaining;
        uint paymentPerMonth;
    }
    donationData[] public donators;
    //we want to give people the option to only donate once monthly for now (keep it easy). otherwise we would have each address have a dynamic array of possible donations;
    mapping (address => uint) public patreonIDs;
    
    //monthly accounting stuff
    uint[13] public ledger;
    //number of patreons
    uint8 constant allPatreonsEver = 0;
    uint8 constant patreonsNow = 1;
    uint8 constant patreonsFinished = 2;
    uint8 constant patreonsCancelled = 3;
    //number of donations
    uint8 constant totalDonationsEver = 4;
    uint8 constant monthlyDonationsAvailable = 5;
    uint8 constant totalDonationsWithdrawn = 6;
    uint8 constant totalDonationsCancelled = 7; 
    //number of ethers
    uint8 constant totalEtherEver = 8;
    uint8 constant totalEtherNow = 9;
    uint8 constant totalEtherWithdrawn = 10;
    uint8 constant totalEtherCancelled = 11;
    //monthly donation
    uint8 constant monthlyDonation = 12;
    
/*********************************************Modifiers, Events, enums***************************************************************************/

    modifier onlyCreator {
        if (msg.sender != creator) 
            revert();
        _; 
    }
    modifier onlyPatreons {
        if (msg.sender == creator) 
            revert();
        _;
    }
    
    //owner is the person who put the PatreonFactory on the blockchain 
    //(so the person organizing the whole thing, has the ability to overpower a creator, as you are using the platform)
    // you dont want a patreon to have ability to withdraw all money, and same with creator (ahead of their time)
    modifier onlyOwner {
        if (msg.sender != owner) 
            revert();
        _;
    }
    
    modifier notInMaintenance {
        healthCheck();
        if (maintenance_mode >= maintenance_Emergency) 
            revert();
        _;
    }
    
    /*
    Creating health check. so you really only need health check what current real balance is, compared to what ledger says
    probably only need it on functions that people can call, and any funciton that paysout or withdrawss
    
    */
    
    
    /* here i am thinking i would like SinglePatreon to only be callable from contractFactory.
    it would have to be deployed though on real net or testnet
    so this is blanked out now, but would be filled in and also one Single Patreon contract would be directly linked to one factory.
    you could always deploy another factory but it wouldn't interact with the other
    this is what is required, because the FRONT END calls upon patreon factory to give a list of names it can donate too
    however IF someone wanted to keep callinig single patreon on their own, it wouldnt effect the patreon factory, which is the main contract
    so it is important that partreon factory can't be messed with or manipulated with entries

    NOTE: it should actually throw at creator = pf.getOringalCreator(contractNumber) - unless called from a patreon contract! (unless someone took made a replica contract whcih returns diff value....)
    
    address createdFactoryAddress = 0x..........;
    modifier onlyFactory {
        if (msg.sender != createdFactoryAddress 
    }
    */
    event LOG_SingleDonation (uint donationAmount, address donator);
    event LOG_PatreonContractCreated (address creator, address createdContract);
    event LOG_ChangeToSingleDonatorStruct (uint totalDonationStart, uint totalRemaining, uint monthsRemaining, uint paymentPerMonth, address donator);
    event LOG_ChangeToFullLedger (uint allPatreonsEver, uint patreonsNow, uint patreonsFinished, uint patreonsCancelled, uint totalDonationsEver, uint monthlyDonationsAvailable, uint totalDonationsWithdrawn, uint totalDonationsCancelled, uint totalEtherEver, uint totalEtherNow, uint totalEtherWithdrawn, uint totalEtherCancelled, uint monthlyDonation);
    event LOG_ChangeToContractBalance (uint contractBalance);
    event LOG_HealthCheck(bytes32 message, uint diff, uint balance, uint ledgerBalance);

/*********************************************CONSTRUCTOR FUNCTIONS AND MAIN FUNCTIONS**************************************************************************/
	function healthCheck() internal {
		uint diff = contractBalance + ledger[totalEtherNow]; //THIS MIGHT FAIL ON MONTHLY CONTRIBUTION. BECAUSE USER SENDS SOME ETHER, BEFORE LEDGER CAN UPDATE
		if (diff == 0) {
			return; // everything ok.
		}
		if (diff > 0) {
			LOG_HealthCheck("Balance too high", diff, contractBalance, ledger[totalEtherNow]);
			maintenance_mode = maintenance_BalTooHigh;
		} else {
			LOG_HealthCheck("Balance too low", diff, contractBalance, ledger[totalEtherNow]);
			maintenance_mode = maintenance_Emergency;
		}
	}

	// manually perform healthcheck.
	// @param _maintenance_mode: 
	// 		0 = reset maintenance_mode, even in emergency
	// 		1 = perform health check
	//    255 = set maintenance_mode to maintenance_emergency (no newPolicy anymore)
	function performHealthCheck(uint8 _maintenance_mode) external onlyOwner {
		maintenance_mode = _maintenance_mode;
		if (maintenance_mode > 0 && maintenance_mode < maintenance_Emergency) {
			healthCheck();
		}
	}
    
    // if ledger gets corrupt for unknown reasons, have a way to correct it, only the owner can do so 
	function auditLedger(uint8 _from, uint8 _to, uint _amount) external onlyOwner {

		ledger[_from] -= uint(_amount);
		ledger[_to] += uint(_amount);
        LOG_ChangeToFullLedger (ledger[allPatreonsEver], ledger[patreonsNow], ledger[patreonsFinished], ledger[patreonsCancelled], ledger[totalDonationsEver], ledger[monthlyDonationsAvailable], ledger[totalDonationsWithdrawn], ledger[totalDonationsCancelled], ledger[totalEtherEver], ledger[totalEtherNow], ledger[totalEtherWithdrawn], ledger[totalEtherCancelled], ledger[monthlyDonation]);

        //NOTE: need to also have here an update to donators struct possible

	}

    function auditDonator(uint _totalRemaining, uint8 _monthsRemaining, uint _patreonID) external onlyOwner {

        donators[_patreonID].totalRemaining = _totalRemaining;
        donators[_patreonID].monthsRemaining = _monthsRemaining;
        LOG_ChangeToSingleDonatorStruct(donators[_patreonID].totalDonationStart,  donators[_patreonID].totalRemaining,  donators[_patreonID].monthsRemaining,  donators[_patreonID].paymentPerMonth,  donators[_patreonID].donator);

    }
	
	
	//owner has a way to send back money to a patreon or a creator 
	//this should also let me test 
	function refundForMistake(address refundee, uint amount) external onlyOwner {

        refundee.transfer(amount);
		maintenance_mode = maintenance_Emergency; // don't allow any contributions or withdrawals
        LOG_ChangeToContractBalance(contractBalance);

	}
    
    
    function SinglePatreon (bytes32 _name, uint _contractNumber) {
        contractNumber = _contractNumber;
        PatreonFactory pf = PatreonFactory(msg.sender);
        name = _name;
        creator = pf.getOriginalCreator(contractNumber); //need to get original creator, not the contract address, to approve the guy to set his limits and withdraw
        owner = pf.getOwner();
    
        LOG_PatreonContractCreated(creator, this);
    }

    function setOneTimeContribution(uint setAmountInWei) external onlyCreator {
        require(0 < setAmountInWei && setAmountInWei < 100 ether); //to prevent overflow and limit max donation to 100 ether
        singleDonationAmount = setAmountInWei;
    }
    
    function oneTimeContribution() external payable onlyPatreons {
        if (msg.value != singleDonationAmount) 
            revert(); 
        
        creator.transfer(msg.value);
        numberOfSingleContributions++;
        //note no log of event here because transfer goes directly to account. no contract involved

      }

    function setMonthlyContribution(uint setMonthlyInWei) external onlyCreator {
        require(0 < setMonthlyInWei && setMonthlyInWei < 1200 ether); //to prevent overflow, and limit to 100 ether a month
        require(setMonthlyInWei % 12 == 0); //making the monthly contributions divisble by 12 for simplicity of a yearly contract, and not losing any wei 
        monthlyDonationAmount = setMonthlyInWei; //you can have the front end display it in ether, but it will be sent in wei and converted front end
    }

    // it appears that this returns function returns nothings
    //the only place where ledger has permanent things added
    //note that ether is straight up sent with this function, so there is no token or ledger transfer here. it just is 
    function monthlyContribution() external payable onlyPatreons notInMaintenance {
        
        if (msg.value != monthlyDonationAmount) 
            revert();
        
        //to ensure that no one makes a double contribution, if it != 0, throw, unless you are the very first one. because all will be 0 if they haven't been created yet
        //also donators.length is needed since donators[0] doesnt exist at the start. it has to be first in the logic, otherwise fail
        if((donators.length >= 1) && (patreonIDs[msg.sender] != 0 || donators[0].donator == msg.sender)) {
            revert();
            }
        
        uint patreonID = donators.length++;
        patreonIDs[msg.sender] = patreonID;
        donationData memory pd = donators[patreonID];
        
        pd.donator = msg.sender;
        pd.totalDonationStart = msg.value;
        pd.totalRemaining = msg.value;
        pd.monthsRemaining = 12;
        pd.paymentPerMonth = msg.value/pd.monthsRemaining;
        
        donators[patreonID] = pd; // i think this is a roundabout way of filling in donators. i make an instance of it, which is just a blank. i fill it in. then i go back and assign it. . i think i could just do it directly? 
        //MAYBE THIS IS CHEAPER THOUGH. i make 5 memorys and one storage change, vs. 5 storage changes     
        
        //this does not work because of integer division. but should work if number is divisable by 12 
        assert(pd.totalRemaining == pd.monthsRemaining*pd.paymentPerMonth);

        
        //is it possible that ether could be sent, and this ledger would not get filled out cuz failure, and then person would effectively lose their 1 year contribution? if so, bad!

        ledger[monthlyDonation] = pd.paymentPerMonth; //right now 0.083. but it could be changed, if i let users pick months. but it gets more difficult. MVP
        ledger[allPatreonsEver] += 1;
        ledger[patreonsNow] += 1;
        assert(ledger[allPatreonsEver] == (ledger[patreonsCancelled]+ledger[patreonsFinished]+ledger[patreonsNow]));
        
        ledger[totalDonationsEver] += 12;
        ledger[monthlyDonationsAvailable] += 12;
        assert(ledger[totalDonationsEver] == ledger[monthlyDonationsAvailable]+ledger[totalDonationsWithdrawn]+ledger[totalDonationsCancelled]);
        
        ledger[totalEtherEver] += msg.value;
        ledger[totalEtherNow] += msg.value;
        assert(ledger[totalEtherEver] == ledger[totalEtherNow]+ledger[totalEtherWithdrawn]+ledger[totalEtherCancelled]);

        LOG_ChangeToFullLedger (ledger[allPatreonsEver], ledger[patreonsNow], ledger[patreonsFinished], ledger[patreonsCancelled], ledger[totalDonationsEver], ledger[monthlyDonationsAvailable], ledger[totalDonationsWithdrawn], ledger[totalDonationsCancelled], ledger[totalEtherEver], ledger[totalEtherNow], ledger[totalEtherWithdrawn], ledger[totalEtherCancelled], ledger[monthlyDonation]);
        LOG_ChangeToSingleDonatorStruct (pd.totalDonationStart,  pd.totalRemaining,  pd.monthsRemaining,  pd.paymentPerMonth,  msg.sender); 
    }

    //ledger here removes things so they can't ever get completed 
    //remember, the patreons HAS already submitted their whole year of ether donations. this function only allows them to claim back some of it 
    //if the creator has not taken their month on August 3rd say, and the person wants their refund, as it stands now they can claim their refund because tardiness of creator
    function patreonCancleMonthly() external onlyPatreons notInMaintenance {
        uint patreonID = patreonIDs[msg.sender];
        
        //this is needed because any msg.sender that has not been created could otherwise steal the first donators cash in here
        if (patreonID == 0 && (msg.sender != donators[0].donator)) {
            revert();
        }
        
        uint refund =  donators[patreonID].totalRemaining;
        
        if (refund == 0)
            revert();
       
        uint monthsRemoved = donators[patreonID].monthsRemaining;
             
        ledger[patreonsCancelled] += 1;
        ledger[patreonsNow] -= 1;
        assert(ledger[allPatreonsEver] == ledger[patreonsCancelled]+ledger[patreonsFinished]+ledger[patreonsNow]);
        
        ledger[monthlyDonationsAvailable] -= monthsRemoved;
        ledger[totalDonationsCancelled] += monthsRemoved;
        assert(ledger[totalDonationsEver] == ledger[monthlyDonationsAvailable]+ledger[totalDonationsWithdrawn]+ledger[totalDonationsCancelled]);

        ledger[totalEtherNow] -= refund;
        ledger[totalEtherCancelled] += refund;
        assert(ledger[totalEtherEver] == ledger[totalEtherNow]+ledger[totalEtherWithdrawn]+ledger[totalEtherCancelled]);
        
        donators[patreonID].totalRemaining = 0;
        donators[patreonID].monthsRemaining = 0;
        
        //won't work, integer division
        assert(donators[patreonID].totalRemaining == donators[patreonID].monthsRemaining*donators[patreonID].paymentPerMonth);

        msg.sender.transfer(refund);

        LOG_ChangeToSingleDonatorStruct (donators[patreonID].totalDonationStart,  donators[patreonID].totalRemaining,  donators[patreonID].monthsRemaining,  donators[patreonID].paymentPerMonth,  donators[patreonID].donator);
        LOG_ChangeToFullLedger (ledger[allPatreonsEver], ledger[patreonsNow], ledger[patreonsFinished], ledger[patreonsCancelled], ledger[totalDonationsEver], ledger[monthlyDonationsAvailable], ledger[totalDonationsWithdrawn], ledger[totalDonationsCancelled], ledger[totalEtherEver], ledger[totalEtherNow], ledger[totalEtherWithdrawn], ledger[totalEtherCancelled], ledger[monthlyDonation]);
        LOG_ChangeToContractBalance(contractBalance);
    }
    
    function checkIfPatreonsAreDoneDonating () internal returns (uint _patreonsDone) {
        uint patreonsDone;
        for (uint x = 0; x<donators.length; x++) {
            donators[x].totalRemaining -= donators[x].paymentPerMonth;
            donators[x].monthsRemaining -= 1;
            assert(donators[x].totalRemaining == donators[x].monthsRemaining*donators[x].paymentPerMonth);
            if (donators[x].monthsRemaining == 0) {
                patreonsDone++;
            }
        }
        return patreonsDone;
    }
    
    //ledger here has things moved from being completed
    ///BUG - SOME REASON IT IS LETTING FULL WITHDRAWAL, repreated
    function creatorWithdrawMonthly() external onlyCreator notInMaintenance { //right now people only contribute for a 12 month term. I GUESS the user 

        if (now > dynamicFirstOfMonth) { //accoridng to this, if guy is two months behind, he can only withdraw one at a time. will need to do 2 transactions
            oneDaySpeedBump();//we want right here just so if creator accidentally calls contract an hour early, he doesnt negate himself a day
            uint amountToWithdraw = ledger[patreonsNow]*ledger[monthlyDonation];
            //deal with patreons in ledger
            ledger[monthlyDonationsAvailable] -= ledger[patreonsNow]; //if there were 5 patreons, 5 monthly donations were withdrawn! so minus that
            ledger[totalDonationsWithdrawn] += ledger[patreonsNow]; 
            assert(ledger[totalDonationsEver] == ledger[monthlyDonationsAvailable]+ledger[totalDonationsWithdrawn]+ledger[totalDonationsCancelled]);

            //deal with ether in ledger
            ledger[totalEtherNow] -= amountToWithdraw;
            ledger[totalEtherWithdrawn] += amountToWithdraw;
            assert(ledger[totalEtherEver] == ledger[totalEtherNow]+ledger[totalEtherWithdrawn]+ledger[totalEtherCancelled]);

            //deal with patreons being fully completed or cancled on ledger
            uint patreonsCompleted = checkIfPatreonsAreDoneDonating();
            ledger[patreonsNow] -= patreonsCompleted;
            ledger[patreonsFinished] += patreonsCompleted;
            assert(ledger[allPatreonsEver] == ledger[patreonsCancelled]+ledger[patreonsFinished]+ledger[patreonsNow]);

            updateMonthlyCounter();

            creator.transfer(amountToWithdraw);
            LOG_ChangeToContractBalance(contractBalance);
            LOG_ChangeToFullLedger (ledger[allPatreonsEver], ledger[patreonsNow], ledger[patreonsFinished], ledger[patreonsCancelled], ledger[totalDonationsEver], ledger[monthlyDonationsAvailable], ledger[totalDonationsWithdrawn], ledger[totalDonationsCancelled], ledger[totalEtherEver], ledger[totalEtherNow], ledger[totalEtherWithdrawn], ledger[totalEtherCancelled], ledger[monthlyDonation]);
        }
        else
            revert();
    }
    function updateMonthlyCounter() internal {
        //make sure months are not trailing off
        assert(monthlyCounter <= 11);
        assert(monthlyCounter >= 0);
        //making sure no overflow has happened
        assert(dynamicFirstOfMonth + 1 > 1498867200);

        //march 31 2020 = 1583020800
        //march 31 20201 = 1614556800
        //march 31 2024 = 1709251200        
        uint64 leapYearCycle = 126230400;//this number is 4 years plus a day, and it reoccuring on a consistent basis

        uint secondsInOneMonth31 = 2678400; // aug, oct dec, jan, mar, may, july
        uint secondsInOneMonth30 = 2592000; //sept, nov, april, june
        uint secondsInOneMonth28 = 2419200; // feb
        uint secondsInOneMonth29 = 2505600; // feb 29 2020, etc.
        
        //if statement that changes dynamicFirstOfMonth, with math. then increment 
        if (monthlyCounter == 7 || monthlyCounter == 9 || monthlyCounter == 11 || monthlyCounter == 0 || monthlyCounter == 2 || monthlyCounter == 4 || monthlyCounter == 6) {
            dynamicFirstOfMonth += secondsInOneMonth31;
            if (monthlyCounter == 11) {
                monthlyCounter = 0;
            } else {
                monthlyCounter++;
            }
        } else if (monthlyCounter == 8 || monthlyCounter == 10 || monthlyCounter == 3 || monthlyCounter == 5) {
            dynamicFirstOfMonth += secondsInOneMonth30;
            monthlyCounter++;
        } else {
            if (now > leapYearCounter) {
                dynamicFirstOfMonth = dynamicFirstOfMonth + secondsInOneMonth29;
                leapYearCounter += leapYearCycle;
                monthlyCounter++;
            } else {
                dynamicFirstOfMonth += secondsInOneMonth28;
                monthlyCounter++;
            }
        }
    }

    function oneDaySpeedBump() internal {
        if(speedBumpBool == true) {
            speedBumpTime = now + 86400;
            speedBumpBool = false;
        } else if (now < speedBumpTime) {
            revert();
        } else {
            speedBumpTime = now + 86400;
        }
    }
/*********************************************GETTER FUNCTIONS AND FALLBACK FUNCTION**************************************************************************/

    function getContractNumber() constant external returns (uint) {
        return contractNumber;
    }

//basically don't need these, since ALL PUBLIC FUNCTIONS HAVE GETTERS
//but three of them are in the front end UI, so I gotta keep em for now 
    function getOneTimecontribution() constant external returns(uint singleDonation) {
        return singleDonationAmount;
    }
      //gets the monthly donation amount entered by contract owner
    function getMonthlyDonationAmount() constant external returns (uint monthlyDonation) {
        return  monthlyDonationAmount;
    }
    //maybe not needed, contract balanace should suffice ?
    function getMonthsLeftForDonation() constant external returns (uint monthsLeft) {
          return ledger[monthlyDonationsAvailable];
    }
    function getContractBalance()  constant external returns(uint contractBalance) {
        return contractBalance;
    }
    function getTotalSingleContributors() constant external returns(uint _numberOfSingleContributions) {
        return numberOfSingleContributions;
    }
    function getOwnerSinglePatreon() constant external returns (address _owner) {
        return owner;
    }

    //owner can only send, the fix any error in withdrawals
    function () onlyOwner {}
    
    }//end contract

/*********************************************FACTORY CONTRACT BELOW**************************************************************************/


contract PatreonFactory {
    bytes32[] public names;
    address[] public newContracts;
    address[] public originalCreators;
    address public owner;
    
    event LOG_NewContractAddress (address indexed theNewcontract, address indexed theContractCreator);
    
    function PatreonFactory () {
        owner = msg.sender;
    }

    //its possible this returns is doing nothing, as i grabbed the contract address from LOGS
    function createContract (bytes32 name) external {
        //loop to prevent duplicate names. uint32 to shorten loop (although still 5 billion)
        for (uint32 i = 0; i<names.length; i++) {
            assert(name != names[i]);
        }
        
        uint contractNumber = newContracts.length;
        originalCreators.push(msg.sender);
        address newContract = new SinglePatreon(name, contractNumber);
        newContracts.push(newContract);
        names.push(name);
        
        LOG_NewContractAddress (newContract, msg.sender);
    } 

    function getName(uint i) constant external returns(bytes32 contractName) {
        return names[i];
    }
    function getContractAddressAtIndex(uint i) constant external returns(address contractAddress) {
        return newContracts[i];
    }
    
    function getOriginalCreator(uint i) constant external returns (address originalCreator) {
        return originalCreators[i];
    }

    function getNameArray() constant external returns(bytes32[] contractName) {
        return names;
    }
    function getContractAddressArray() constant external returns(address[] contractAddress) {
        return newContracts;
    }
    
    function getOriginalCreatorArray() constant external returns (address[] originalCreator) {
        return originalCreators;
    }
    
    function getOwner() constant external returns (address _owner) {
        return owner;
    }

    function () {} //can't send ether with send unless payable modifier exists
}
/*

Story script for first explaination of a dApp

Patreon Factory
- this is your common factory for making something over and over again which is a common coding practice. lets break it down
- create contract takes a name, which is the name of your contract
- it ends up returning the new contract address, the name of it (bytes32 because thats the only way contracts can interact), the uint of the contract, and the address of the person who called it
- what the fucntion does. 
    it created a contract, increases the length of newContracts 
    it saves the address that created this contract with a push into a dynamic array
    then it creates a new contract, passing the two values it needs to that contract function
    two more pushes to save newContract and name
    then we LOG both address (this may be gone)
- thats about it. it also has three getter functions for convience sakes (i only know of one that is used right now)d

Single Patreon Contract
- The ledger
    the ledger is needed in order to record values that people have donated, who has donated, and what has
    been done with the donations over time. These numbers are stricly ledger numbers, and dont represent real ether
    but they have to be used to be able to transfer ether, and update the ledgers. if the ledger gets fucked up
    ether wont get sent around properly 
    - need to explain why its [13]

- struct donationData
    this holds donators address, donations remaining and starting

- [] donators
    a dynamic array of the struct above

- mapping patreonIDs
    mapping realting eth address to the patreon ID

-function SinglePAtreon (constructor)
    just gives the contract a name, a number, and creators address (through use of getter function from factory)

-function SetOneTimecontribution)
    a funciton only the creator can call, which allows them to determine how much a one time donor can give to them. 1$, 10$, .1 ether. customizable
    
-function oneTimeContribution() 
    just straight up trasfers the money to creaotr address. 
    logs it to show it happens
    increases the number of single contributions 

-function setMonthlyContribution ()

-function monthlyContribution ()
    elaborate way to prevent duplicate monthly contributions
    make a patreonID
    set the patreonIDs mapping to match address to patreon ID
    save donationData struct in memory and name if pd
        this part is weird and round about but figure out why it is all done at once instead of 5 seperate
    just update ledger

-function patreonCancleMonthly()
    make sure correct patreonID is grabbed form address
    block the thing from 0 address
    revert if already 0
    figure out moths removed
    update full ledger
    then send refund (always do after)

-function checkIfPAtreonsAreDoneDonating ()
    inetnal function to know when to stop taking a donation for the next month
    called from creatorWithdrawMonthly

-function creatorWithdrawMonthly
    uses time to figure out when the first of each month will be
    needs to dunamically change it with a lot of logic
    this could be a seperate contract
    figures out amount to withdraw (right now a constant eth amount and a variable donator amount)
    update ledger
    check if anyones done
    update ledger
    transfer

    then a big if funciton to figure out which month it is, so it knows the unix time for the next release
    */