pragma solidity ^0.4.12;

contract SinglePatreon {
    
/*********************************************STATE VARIABLES***************************************************************************/

    address public creator;
    bytes32 public name;
    uint public singleDonationAmount;
    uint public monthlyDonationAmount;
    uint contractNumber;
    uint monthlyCounter = 6; //because we are starting on aug 2017, and its 7th spot in a 12 spot array ************CHANGED TO 6 for TEST
    uint  leapYearCounter = 1583020800;
    uint constant leapYearCycle = 126230400;//this number is 4 years plus a day, and it reoccuring on a consistent basis
    uint contractBalance = this.balance;
    uint numberOfSingleContributions;
    
    struct donationData {
        address donator;
        uint totalDonationStart;
        uint totalRemaining;
        uint monthsRemaining;
        uint paymentPerMonth;
    }
    donationData[] public donators;
    //we want to give people the option to only donate once monthly for now (keep it easy). otherwise we would have each address have a dynamic array of possible donations;
    mapping (address => uint) public patreonIDs;

    
    //monthly accounting stuff
    uint[13] public ledger;
    //number of patreons
    uint constant allPatreonsEver = 0;
    uint constant patreonsNow = 1;
    uint constant patreonsFinished = 2;
    uint constant patreonsCancelled = 3;
    //number of donations
    uint constant totalDonationsEver = 4;
    uint constant monthlyDonationsAvailable = 5;
    uint constant totalDonationsWithdrawn = 6;
    uint constant totalDonationsCancelled = 7; 
    //number of ethers
    uint constant totalEtherEver = 8;
    uint constant totalEtherNow = 9;
    uint constant totalEtherWithdrawn = 10;
    uint constant totalEtherCancelled = 11;
    //monthly donation
    uint constant monthlyDonation = 12; // 0.083, but do i need this constant? 
    
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
    
    event LOG_SingleDonation (uint donationAmount, address donator);
    event LOG_Withdraw (uint emptyBalance);
    event LOG_creatorAddressAndSender (address factoryAddress, address creator);
    event LOG_ShowAllMonthlyDonationsOneUser (uint totalDonationStart, uint totalRemaining, uint monthsRemaining, uint paymentPerMonth, address donator);
    event LOG_FullLedger(uint allPatreonsEver, uint patreonsNow, uint patreonsFinished, uint patreonsCancelled, uint totalDonationsEver, uint monthlyDonationsAvailable, uint totalDonationsWithdrawn, uint totalDonationsCancelled, uint totalEtherEver, uint totalEtherNow, uint totalEtherWithdrawn, uint totalEtherCancelled, uint monthlyDonation);
    event LOG_ContractBalance(uint contractBalance);

/*********************************************CONSTRUCTOR FUNCTIONS AND MAIN FUNCTIONS**************************************************************************/

    function SinglePatreon (bytes32 _name, uint _contractNumber) payable {
        contractNumber = _contractNumber;
        PatreonFactory pf = PatreonFactory(msg.sender);
        name = _name;
        creator = pf.getOriginalCreator(contractNumber); //need to get original creator, not the contract address, to approve the guy to set his limits and withdraw
    
        LOG_creatorAddressAndSender(msg.sender, creator);//msg.sender is the factory. creator is the guy who made it. it gets logged at bytes32 in events, i guess because thats all that contracts can pass to each other
    }

    function setOneTimeContribution(uint setAmountInWei) onlyCreator  returns(uint) {
        singleDonationAmount = setAmountInWei;
        return singleDonationAmount;
    }
    
    function oneTimeContribution() payable onlyPatreons {
        if (msg.value != singleDonationAmount) 
            revert(); 
        
        LOG_ContractBalance(this.balance);
        creator.transfer(msg.value);
        LOG_ContractBalance(this.balance);
        numberOfSingleContributions++;

      }

    function setMonthlyContribution(uint setMonthlyInWei) onlyCreator  returns(uint) {
        monthlyDonationAmount = setMonthlyInWei; //you can have the front end display it in ether, but it will be sent in wei and converted front end
        return monthlyDonationAmount;
    }

    // it appears that this returns function returns nothings
    //the only place where ledger has permanent things added
    //note that ether is straight up sent with this function, so there is no token or ledger transfer here. it just is 
    function monthlyContribution() payable onlyPatreons returns(uint) {
        
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
        assert(pd.totalRemaining == pd.monthsRemaining*pd.paymentPerMonth);

        
        //is it possible that ether could be sent, and this ledger would not get filled out cuz failure, and then person would effectively lose their 1 year contribution? if so, bad!

        ledger[monthlyDonation] = pd.paymentPerMonth; //right now 0.083. but it could be changed, if i let users pick months. but it gets more difficult. MVP
        ledger[allPatreonsEver] += 1;
        ledger[patreonsNow] += 1;
        assert(ledger[allPatreonsEver] == ledger[patreonsCancelled]+ledger[allPatreonsEver]+ledger[patreonsNow]);
        
        ledger[totalDonationsEver] += 12;
        ledger[monthlyDonationsAvailable] += 12;
        assert(ledger[totalDonationsEver] == ledger[monthlyDonationsAvailable]+ledger[totalDonationsWithdrawn]+ledger[totalDonationsCancelled]);
        
        ledger[totalEtherEver] += 1 ether;
        ledger[totalEtherNow] += 1 ether;
        assert(ledger[totalEtherEver] == ledger[totalEtherNow]+ledger[totalEtherWithdrawn]+ledger[totalEtherCancelled]);


        LOG_ShowAllMonthlyDonationsOneUser ( pd.totalDonationStart,  pd.totalRemaining,  pd.monthsRemaining,  pd.paymentPerMonth,  msg.sender); 
    }

    //ledger here removes things so they can't ever get completed 
    //remember, the patreons HAS already submitted their whole year of ether donations. this function only allows them to claim back some of it 
    //if the creator has not taken their month on August 3rd say, and the person wants their refund, as it stands now they can claim their refund because tardiness of creator
    function patreonCancleMonthly() onlyPatreons {
        uint patreonID = patreonIDs[msg.sender];
        
        //this is needed because any msg.sender that has not been created could otherwise steal the first donators cash in here
        if (patreonID == 0 && (msg.sender != donators[0].donator)) {
            revert();
        }
        
        LOG_ShowAllMonthlyDonationsOneUser ( donators[patreonID].totalDonationStart,  donators[patreonID].totalRemaining,  donators[patreonID].monthsRemaining,  donators[patreonID].paymentPerMonth,  donators[patreonID].donator);
        uint refund =  donators[patreonID].totalRemaining;
        
        if (refund == 0)
            revert();
       
        uint monthsRemoved = donators[patreonID].monthsRemaining;
       
        LOG_FullLedger(ledger[allPatreonsEver], ledger[patreonsNow], ledger[patreonsFinished], ledger[patreonsCancelled], ledger[totalDonationsEver], ledger[monthlyDonationsAvailable], ledger[totalDonationsWithdrawn], ledger[totalDonationsCancelled], ledger[totalEtherEver], ledger[totalEtherNow], ledger[totalEtherWithdrawn], ledger[totalEtherCancelled], ledger[monthlyDonation]);
        LOG_ContractBalance(this.balance);
      
        ledger[patreonsCancelled] += 1;
        ledger[patreonsNow] -= 1;
        assert(ledger[allPatreonsEver] == ledger[patreonsCancelled]+ledger[allPatreonsEver]+ledger[patreonsNow]);
        
        ledger[monthlyDonationsAvailable] -= monthsRemoved;
        ledger[totalDonationsCancelled] += monthsRemoved;
        assert(ledger[totalDonationsEver] == ledger[monthlyDonationsAvailable]+ledger[totalDonationsWithdrawn]+ledger[totalDonationsCancelled]);

        ledger[totalEtherNow] -= refund;
        ledger[totalEtherCancelled] += refund;
        assert(ledger[totalEtherEver] == ledger[totalEtherNow]+ledger[totalEtherWithdrawn]+ledger[totalEtherCancelled]);
        
        donators[patreonID].totalRemaining = 0;
        donators[patreonID].monthsRemaining = 0;
        assert(donators[patreonID].totalRemaining == donators[patreonID].monthsRemaining*donators[patreonID].paymentPerMonth);

        msg.sender.transfer(refund);

        LOG_FullLedger(ledger[allPatreonsEver], ledger[patreonsNow], ledger[patreonsFinished], ledger[patreonsCancelled], ledger[totalDonationsEver], ledger[monthlyDonationsAvailable], ledger[totalDonationsWithdrawn], ledger[totalDonationsCancelled], ledger[totalEtherEver], ledger[totalEtherNow], ledger[totalEtherWithdrawn], ledger[totalEtherCancelled], ledger[monthlyDonation]);
        LOG_ContractBalance(this.balance);
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
    function creatorWithdrawMonthly() onlyCreator { //right now people only contribute for a 12 month term. I GUESS the user 
        
        //march 31 2020 = 1583020800
        //march 31 20201 = 1614556800
        //march 31 2024 = 1709251200
        
        //july 1st 2017, to test one month withdrawl = 1498867200;
        
        uint dynamicFirstOfMonth = 1498867200; //starts on August 1st, 2017
        
        uint secondsInOneMonth31 = 2678400; // aug, oct dec, jan, mar, may, july
        uint secondsInOneMonth30 = 2592000; //sept, nov, april, june
        uint secondsInOneMonth28 = 2419200; // feb
        uint secondsInOneMonth29 = 2505600; // feb 29 2020, etc.
        
        //making sure no overflow has happened
        assert(dynamicFirstOfMonth > 1498867200);
        //make sure months are not trailing off
        assert(monthlyCounter >= 12);
        assert(monthlyCounter <= 0);
        
        if (now > dynamicFirstOfMonth) { //accoridng to this, if guy is two months behind, he can only withdraw one at a time. will need to do 2 transactions

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
            assert(ledger[allPatreonsEver] == ledger[patreonsCancelled]+ledger[allPatreonsEver]+ledger[patreonsNow]);

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

            LOG_ContractBalance(this.balance);
            creator.transfer(amountToWithdraw);
            LOG_ContractBalance(this.balance);
            LOG_FullLedger(ledger[allPatreonsEver], ledger[patreonsNow], ledger[patreonsFinished], ledger[patreonsCancelled], ledger[totalDonationsEver], ledger[monthlyDonationsAvailable], ledger[totalDonationsWithdrawn], ledger[totalDonationsCancelled], ledger[totalEtherEver], ledger[totalEtherNow], ledger[totalEtherWithdrawn], ledger[totalEtherCancelled], ledger[monthlyDonation]);
        }
    }
/*********************************************GETTER FUNCTIONS AND FALLBACK FUNCTION**************************************************************************/

    function getOneTimecontribution() constant returns(uint singleDonation) {
        return singleDonationAmount;
    }
      //gets the monthly donation amount entered by contract owner
    function getMonthlyDonationAmount() constant returns (uint monthlyDonation) {
        return  monthlyDonationAmount;
    }
    //maybe not needed, contract balanace should suffice ?
    function getMonthsLeftForDonation() constant returns (uint monthsLeft) {
          return ledger[monthlyDonationsAvailable];
    }
    function getContractBalance()  constant returns(uint contractBalance) {
        return this.balance;
    }
    function () {} //fallback function.  dont accept ether to this contract without calling the constructor function or others. this way, people dont accidentally burn their money
    }//end contract

/*********************************************FACTORY CONTRACT BELOW**************************************************************************/


contract PatreonFactory {
    bytes32[] names;
    address[] newContracts;
    address[] originalCreators;
    
    address factoryAddress = this;
    
    event LOG_NewContractAddress (address theNewcontract, address indexed theContractCreator);

    function createContract (bytes32 name) returns(address theNewContract, bytes32 contractName, uint contractNum, address creatorAddress) {
        uint contractNumber = newContracts.length;
        originalCreators.push(msg.sender);
        address newContract = new SinglePatreon(name, contractNumber);
        newContracts.push(newContract);
        names.push(name);
        
        LOG_NewContractAddress (newContract, msg.sender);
        return (newContract, name, contractNumber, msg.sender);
    } 

    function getName(uint i) constant returns(bytes32 contractName) {
        return names[i];
    }
    function getContractAddressAtIndex(uint i) constant returns(address contractAddress) {
        return newContracts[i];
    }
    
    function getOriginalCreator(uint i) constant returns (address originalCreator) {
        return originalCreators[i];
    }

    function getNameArray() constant returns(bytes32[] contractName) {
        return names;
    }
    function getContractAddressArray() constant returns(address[] contractAddress) {
        return newContracts;
    }
    
    function getOriginalCreatorArray() constant returns (address[] originalCreator) {
        return originalCreators;
    }

    function () {}
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