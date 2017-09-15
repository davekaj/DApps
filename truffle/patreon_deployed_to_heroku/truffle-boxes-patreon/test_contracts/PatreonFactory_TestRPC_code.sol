pragma solidity ^0.4.13;

contract SinglePatreon {
    
/*********************************************STATE VARIABLES***************************************************************************/

    address public creator;
    address public owner;
    bytes32 public name; //contract name 
    uint public singleDonationAmount;
    uint public monthlyDonationAmount;
    uint public contractNumber; // having trouble getting this from web3
    uint32 public numberOfSingleContributions;

    //monthly Counter Variables
    //both are currently july. good 
    uint dynamicFirstOfMonth = 1498867200; //starts on July 1st, 2017. JUST REMOVED THIS FROM function and made state variable. This should fix problem of creator doing unlimited withdrawals
    uint8 monthlyCounter = 6; //because we are starting on aug 2017, and its 7th spot in a 12 spot array ************CHANGED TO 6 for TEST
    uint64 leapYearCounter = 1583020800; //did not add an assert for this, as it can't be changed easily
    
    //maintenance modes 
    uint8 constant maintenanceNone = 0;
    uint8 constant maintenance_BalTooHigh = 1;
    uint8 constant maintenance_Emergency = 255;
    uint8 public maintenance_mode;

    //speedBump Variables
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
    //patreonCancelMonthly has its own code that makes sure people who have never contributed can't withdraw
    modifier onlyPatreons {
        if (msg.sender == creator) 
            revert();
        _;
    }
    
    //owner is the person who put the PatreonFactory on the blockchain 
    //They have the ability to Fix contract ledger if there are mistakes
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
        
    event LOG_SingleDonation (uint donationAmount, address donator);
    event LOG_PatreonContractCreated (address creator, address createdContract);
    event LOG_ChangeToSingleDonatorStruct (uint totalDonationStart, uint totalRemaining, uint monthsRemaining, uint paymentPerMonth, address donator);
    event LOG_ChangeToFullLedger (uint allPatreonsEver, uint patreonsNow, uint patreonsFinished, uint patreonsCancelled, uint totalDonationsEver, uint monthlyDonationsAvailable, uint totalDonationsWithdrawn, uint totalDonationsCancelled, uint totalEtherEver, uint totalEtherNow, uint totalEtherWithdrawn, uint totalEtherCancelled, uint monthlyDonation);
    event LOG_ChangeToContractBalance (uint contractBalance);
    event LOG_HealthCheck(bytes32 message, int diff, uint balance, uint ledgerBalance);

/*********************************************HEALTH CHECK FUNCTIONS**************************************************************************/
	

    function healthCheck() internal {
        // minus msg.value becuase the contract balance increases at start from payable functions, and ledger only decreases at end of payable function
    	int diff = int(this.balance-msg.value) - int(ledger[totalEtherNow]);//needs to be int for negative
		if (diff == 0) {
			return; // everything is ok.
		}
		if (diff > 0) {
			LOG_HealthCheck("Balance too high", diff, this.balance, ledger[totalEtherNow]);
			maintenance_mode = maintenance_BalTooHigh;
		} else {
			LOG_HealthCheck("Balance too low", diff, this.balance, ledger[totalEtherNow]);
			maintenance_mode = maintenance_Emergency;
		}
	}

	// manually perform healthcheck.
	// 		0 = reset maintenance_mode, even in emergency
	// 		1 = perform health check
	//    255 = set maintenance_mode to maintenance_emergency (no newPolicy
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

	}
    //if a mistake is noticed, have a way to update the specific donators struct so they can cancle the proper amount
    function auditDonator(uint _totalRemaining, uint8 _monthsRemaining, uint _patreonID) external onlyOwner {

        donators[_patreonID].totalRemaining = _totalRemaining;
        donators[_patreonID].monthsRemaining = _monthsRemaining;
        LOG_ChangeToSingleDonatorStruct(donators[_patreonID].totalDonationStart,  donators[_patreonID].totalRemaining,  donators[_patreonID].monthsRemaining,  donators[_patreonID].paymentPerMonth,  donators[_patreonID].donator);

    }
	
	
	//owner has a way to send back money to a patreon or a creator 
	//this can also be used to help test
	function refundForMistake(address refundee, uint amount) external onlyOwner {

        refundee.transfer(amount);
		maintenance_mode = maintenance_Emergency; // don't allow any contributions or withdrawals
        LOG_ChangeToContractBalance(this.balance);

	}
    
/*********************************************CONSTRUCTOR FUNCTIONS AND MAIN FUNCTIONS**************************************************************************/

     
    // SinglePatreons should all be linked to the factory they were created from 
    // If a Single patreon is not creator by a factory, it will fail because of "PatreonFactory pf = PatreonFactory(msg.sender)"
    // Front end of app should allow for a factory address to be called upon, which then would have all the singlePatreons ever created
    function SinglePatreon (bytes32 _name, uint _contractNumber) {
        contractNumber = _contractNumber;
        PatreonFactory pf = PatreonFactory(msg.sender);
        name = _name;
        creator = pf.getOriginalCreator(contractNumber); //need to get original creator, not the contract address, to approve the guy to set his limits and withdraw
        owner = pf.getOwner();
        LOG_PatreonContractCreated(creator, this);
    }

    //allows creator to decide how much a patreon can donate to them with a one time donation.
    function setOneTimeContribution(uint setAmountInWei) external onlyCreator {
        require(0 < setAmountInWei && setAmountInWei < 100 ether); //to prevent overflow and limit max donation to 100 ether
        singleDonationAmount = setAmountInWei;
    }
    
    //allows anyone (except the creator) to dontate a one time donation to the creator
    function oneTimeContribution() external payable onlyPatreons {
        if (msg.value != singleDonationAmount) 
            revert(); 
        
        creator.transfer(msg.value);
        numberOfSingleContributions++;
        //note no log of event here because transfer goes directly to account. no ether value change in the contract 

      }

    //allows creator to decide how much a patreon can donate to them monthly. 
    //It is designed to take a years worth, and that is released monthly to the creator, with the ability for the patreon to cancle at any time and get refunded
    function setMonthlyContribution(uint setMonthlyInWei) external onlyCreator {
        require(0 < setMonthlyInWei && setMonthlyInWei < 1200 ether); //to prevent overflow, and limit to 100 ether a month
        require(setMonthlyInWei % 12 == 0); //making the monthly contributions divisble by 12 for simplicity of a yearly contract, and not losing any wei 
        monthlyDonationAmount = setMonthlyInWei; 
    }

    //Anyone (except creator) can submit a years worth of contributions to the patreon here
    //the only place where ledger has permanent things added
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
        
        donators[patreonID] = pd; 
        //i think this is a roundabout way of filling in donators. i make an instance of it, which is just a blank. i fill it in. then i go back and assign it. . i think i could just do it directly? 
        //MAYBE THIS IS CHEAPER THOUGH. i make 5 memorys and one storage change, vs. 5 storage changes     
        
        //this does not work because of integer division, but we stricky require setMonthly to be % 12, so integer div will always return an int 
        assert(pd.totalRemaining == pd.monthsRemaining*pd.paymentPerMonth);

        

        ledger[monthlyDonation] = pd.paymentPerMonth;
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

    //remember, the patreons HAS already submitted their whole year of ether donations. this function only allows them to claim back some of it 
    //if the creator has not taken their month on August 3rd (with August 1st being the day new withdrawals are released), and the person wants their refund, as it stands now they can claim their refund because tardiness of creator
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
        
        //must be integer division that results in integers
        assert(donators[patreonID].totalRemaining == donators[patreonID].monthsRemaining*donators[patreonID].paymentPerMonth);

        msg.sender.transfer(refund);

        LOG_ChangeToSingleDonatorStruct (donators[patreonID].totalDonationStart,  donators[patreonID].totalRemaining,  donators[patreonID].monthsRemaining,  donators[patreonID].paymentPerMonth,  donators[patreonID].donator);
        LOG_ChangeToFullLedger (ledger[allPatreonsEver], ledger[patreonsNow], ledger[patreonsFinished], ledger[patreonsCancelled], ledger[totalDonationsEver], ledger[monthlyDonationsAvailable], ledger[totalDonationsWithdrawn], ledger[totalDonationsCancelled], ledger[totalEtherEver], ledger[totalEtherNow], ledger[totalEtherWithdrawn], ledger[totalEtherCancelled], ledger[monthlyDonation]);
        LOG_ChangeToContractBalance(this.balance);
    }

    ///Allows creator to withdraw one monthly donation from however many patreons they currnetly have
    //only once a month, max once a day
    function creatorWithdrawMonthly() external onlyCreator notInMaintenance {
       
       //if there is nothing to withdraw, dont go through the operations
       if (ledger[monthlyDonationsAvailable] <= 0) {
           revert();
       }
       //@@@@@@@@@@@@@@@TESTING. GET RID OF TEMP, PUT IN DYNAMIC NORMAL
        uint tempDynamicFirstOfMonthForTesting = 1498867200;
        //@@@@@@@@@@@@@@@TESTING
        if (now > tempDynamicFirstOfMonthForTesting) { //accoridng to this, if guy is two months behind, he can only withdraw one at a time. will need to do 2 transactions
           //@@@@@@@@@@@@@@@TESTING comment out oneDaySpeedBump
            oneDaySpeedBump();//must be inside this if statement since if creator accidentally calls contract an hour early, he doesnt negate himself a day
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
            //uint patreonsCompleted = 0; @@@@@@@@@@@@@@@TESTING off
            uint patreonsCompleted = checkIfPatreonsAreDoneDonating();
            ledger[patreonsNow] -= patreonsCompleted;
            ledger[patreonsFinished] += patreonsCompleted;
            assert(ledger[allPatreonsEver] == ledger[patreonsCancelled]+ledger[patreonsFinished]+ledger[patreonsNow]);

            updateMonthlyCounter();

            creator.transfer(amountToWithdraw);
            LOG_ChangeToContractBalance(this.balance);
            LOG_ChangeToFullLedger (ledger[allPatreonsEver], ledger[patreonsNow], ledger[patreonsFinished], ledger[patreonsCancelled], ledger[totalDonationsEver], ledger[monthlyDonationsAvailable], ledger[totalDonationsWithdrawn], ledger[totalDonationsCancelled], ledger[totalEtherEver], ledger[totalEtherNow], ledger[totalEtherWithdrawn], ledger[totalEtherCancelled], ledger[monthlyDonation]);
        }
        else
            revert();
    }
        
    //intenal function to check How many Patreons are done donating, so ledger[patreonsNow] and ledger[patreonscompleted] can be properly updated
    function checkIfPatreonsAreDoneDonating () internal returns (uint _patreonsDone) {
        uint patreonsDone;

        for (uint x = 0; x<donators.length; x++) {
            if (donators[x].totalRemaining > 0) { //ignore ones already 0
                donators[x].totalRemaining -= donators[x].paymentPerMonth;
                donators[x].monthsRemaining -= 1;
                assert(donators[x].totalRemaining == donators[x].monthsRemaining*donators[x].paymentPerMonth);
                if (donators[x].monthsRemaining == 0) {// if its now 0, update ledger
                    patreonsDone++;
                }
            }
        }
        return patreonsDone;
    }
    
    //internal
    //allows for contract to be run and have correct unix time stamps for each month
    function updateMonthlyCounter() internal {
        //@@@@@@@@@@@@@@@TESTING
        uint tempDynamicFirstOfMonthForTesting = 1498867200;
        //make sure months are not trailing off
        assert(monthlyCounter <= 11);
        assert(monthlyCounter >= 0);

        //@@@@@@@@@@@@@@@TESTING
        //making sure no overflow has happened
        assert(tempDynamicFirstOfMonthForTesting + 1 > 1498867200);


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

    //internal function that prevents creator from withdrawing a bunch at once IF there is a bug
    //normally it is limited to once a month. this allows for only one a day to be allowed as well
    //functionally, it should only change the case where a creator hasn't withdrawn for 2 months
    //and has to take 2 days to do so instead of doing both in a row
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

//basically don't need these, since ALL PUBLIC FUNCTIONS HAVE GETTERS
//but three of them are in the front end UI, so I gotta keep em for now 
//but some work and some don't with testing. having problems with uints

    function getContractNumber() constant external returns (uint) {
        return contractNumber;
    }
    function getOneTimecontribution() constant external returns(uint singleDonation) {
        return singleDonationAmount;
    }
    function getMonthlyDonationAmount() constant external returns (uint monthlyDonation) {
        return  monthlyDonationAmount;
    }
    //maybe not needed, contract balanace should suffice ?
    function getMonthsLeftForDonation() constant external returns (uint monthsLeft) {
          return ledger[monthlyDonationsAvailable];
    }
    function getContractBalance()  constant external returns(uint contractBalance) {
        return this.balance;
    }
    function getTotalSingleContributors() constant external returns(uint _numberOfSingleContributions) {
        return numberOfSingleContributions;
    }
    function getOwnerSinglePatreon() constant external returns (address _owner) {
        return owner;
    }
    function getPatreonID(address patreonsAddress) constant external returns (uint _id) {
        return patreonIDs[patreonsAddress];
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
    
    //Owner is passed onto every SinglePatreon Contract, so that owner can have power to adjust ledger
    function PatreonFactory () {
        owner = msg.sender;
    }

    //creates the singlePatreon contract and saves important info within this contract
    function createContract (bytes32 name) external {
        //loop to prevent duplicate names of contracts created, to avoid confusion. 
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