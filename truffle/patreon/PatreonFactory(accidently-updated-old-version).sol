pragma solidity ^0.4.13;


//would be nice to have a UI that will actually show on www.blockchainpatreon.com the countdown till they can withdraw money :)


/*

CREATOR
-so the contract allows for acceptance of money to the contract specifically
    constructor 
-give the creator control, he and only he can withdraw when he wants
    one function
-creator customizes the project so he can decide (for now, maybe hardcoded 1$ donatations, that reoccur monthly. and then a one time payment
    two functions)

PATREON
-have a reoccuring payment
-have a single payment 
-be able to see what the artist does




DAPP DEVELOPER
-doesnt get any fees
-will still have to be some fees to operate the contract? maybe or maybe not. if so need a fund. look at my other contract to see if it was just orazclize and betting funds
- indexed
    what type of artist they are
    their website orrrr title of there account
    the contract address (i think auto indexed)
- but dapp dev is able to set up the firsts contract ever, which is there so people can donate to it so he can develope the acutal platform 
- elaborate how this is a better model than getting paid 1% of everything. cuz its open source stuff



does not have 10% fees!


*/



/*********************************************Modifiers, Events, enums***************************************************************************/



/*********************************************Constants, Mappings and Structs***************************************************************************/




/*********************************************Contstructor  Function and Main Functions Specific to patreon**************************************************************************/




//does this need a fallback???????^^

contract SinglePatreon { //should make this only callable by Patreon Factory 
    bytes32 public name;
    uint public singleDonationAmount; //i think it is 0 automatically, we will see
    uint public monthlyDonationAmount;
    address public creator;
    uint contractNumber;
    uint monthlyCounter = 6; //because we are starting on aug 2017, and its 7th spot in a 12 spot array ************CHANGED TO 6 for TEST
    uint constant leapYearCounter = 1583020800;
    uint constant leapYearCycle = 126230400;//this number is 4 years plus a day, and it reoccuring on a consistent basis
    uint contractBalance = this.balance;

    
    //accounting stuff
    uint[13] public ledger;
    
    uint constant allPatreonsEver = 0; // 10
    uint constant patreonsNow = 1;  // 10 still
    uint constant patreonsFinished = 2; // 0
    uint constant patreonsCancelled = 3; //0
    
    uint constant totalDonationsEver = 4; //
    uint constant monthlyDonationsAvailable = 5; //113
    uint constant totalDonationsWithdrawn = 6; //7
    uint constant totalDonationsCancelled = 7; //0 
    
    uint constant totalEtherEver = 8; // 10 
    uint constant totalEtherNow = 9;  // ~8.5 ether
    uint constant totalEtherWithdrawn = 10; // ~1.5 ether
    uint constant totalEtherCancelled = 11; //0
    
    uint constant monthlyDonation = 12; // 0.083, but do i need this constant? 
    
    
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
    
    struct donationData {
        address donator;
        uint totalDonationStart;
        uint totalRemaining;
        uint monthsRemaining;
        uint paymentPerMonth;
    }
    
    
    donationData[] public donators;
    
    
    //we want to give people the option to only donate once for now (keep it easy);
    mapping (address => uint) public patreonIDs;
   // mapping (address => donationData) public patreonDonations; //i think this is needed for lookup of when someone wants to cancle to make that simple. lets keep it

    
    function SinglePatreon (bytes32 _name, uint _contractNumber) payable {
      //  creator = tx.origin; //this might be a bug 
        
        contractNumber = _contractNumber;
        PatreonFactory pf = PatreonFactory(msg.sender);
        name = _name;
        creator = pf.getOriginalCreator(contractNumber); //need to get original creator, not the contract address, to approve the guy to set his limits and withdraw
        
    LOG_creatorAddressAndSender(msg.sender, creator);//msg.sender ISapparently the SinglePatreon Contract and NOT the factory. i guess the contract SinglePatreon is calling the constructor function!

    }

    function setOneTimeContribution(uint setAmountInWei) onlyCreator  returns(uint){
        singleDonationAmount = setAmountInWei;
        return singleDonationAmount;
    }

    function setMonthlyContribution(uint setMonthlyInWei) onlyCreator  returns(uint) {
        monthlyDonationAmount = setMonthlyInWei; //you can have the front end display it in ether, but it will be sent in wei and converted front end
        

        return monthlyDonationAmount;
    }

    function oneTimeContribution() payable onlyPatreons returns(uint){
        if (msg.value != singleDonationAmount) revert(); 
        //this.balance = this.balance + msg.value;
        //  msg.sender.send()
        
        LOG_SingleDonation(this.balance, msg.sender);
        
        return this.balance;
      }

    //the only place where ledger has permanent things added
    function monthlyContribution() payable onlyPatreons returns(uint) {
        
        if (msg.value != monthlyDonationAmount) revert();
        
        
        //to ensure that no one makes a double contribution, if it != 0, throw, unless you are the very first one. because all will be 0 if they haven't been created yet
        //also donators.length is needed since donators[0] doesnt exist at the start. it has to be first in the logic, otherwise fail
        if((donators.length >= 1) && (patreonIDs[msg.sender] != 0 || donators[0].donator == msg.sender)){
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
        
        
        ledger[monthlyDonation] = pd.paymentPerMonth; //right now 0.083. but it could be changed, if i let users pick months. but it gets more difficult. MVP
        
        ledger[allPatreonsEver] += 1;
        ledger[patreonsNow] += 1;
        ledger[totalDonationsEver] += 12;
        ledger[monthlyDonationsAvailable] += 12;
        ledger[totalEtherEver] += 1 ether;
        ledger[totalEtherNow] += 1 ether;

        
        LOG_ShowAllMonthlyDonationsOneUser ( pd.totalDonationStart,  pd.totalRemaining,  pd.monthsRemaining,  pd.paymentPerMonth,  msg.sender); 
        //XXXXXXXXXthis log shows all monthly donations for one sender. not all senders
        //XXXXXXXXX it also does not let someone donate twice properly. it just overwrites the previous donation. 
        // so i think it would be best to only allow someone to donate once
    
        

    }

//might be able to remove the yearly thing if we can get the incrementor working

    //ledger here removes things so they can't ever get completed 
    //remember, the patreons TECHNICALLY already submitted their whole year. this function only allows them to claim back some of it 
    function patreonCancleMonthly() onlyPatreons {
        
        //can easily call this one, because the address that calls it can only reference its own struct. 

        //the problem with this one is that, each individual patreon has to have their struct update when a new month happens. 
        
        // which just means that that will have to be a part of the withdraw function
        
        //it should be static though. and if a creator hasnt withdrwan their funds yet then they will get back their money even though they shouldnt have
        
        // this will also have to alter state variables
        
        
        //XXXXtry doing the memory thing
        
        uint patreonID = patreonIDs[msg.sender];
        
        //this is needed because any msg.sender that has not been created could otherwise steal the first donators cash in here
        if (patreonID == 0 && (msg.sender != donators[0].donator)){
            revert();
        }
        
        LOG_ShowAllMonthlyDonationsOneUser ( donators[patreonID].totalDonationStart,  donators[patreonID].totalRemaining,  donators[patreonID].monthsRemaining,  donators[patreonID].paymentPerMonth,  donators[patreonID].donator);
        uint refund =  donators[patreonID].totalRemaining;
        
        
       
        if (refund == 0) revert();
       
        uint monthsRemoved = donators[patreonID].monthsRemaining;
       
        LOG_FullLedger(ledger[allPatreonsEver], ledger[patreonsNow], ledger[patreonsFinished], ledger[patreonsCancelled], ledger[totalDonationsEver], ledger[monthlyDonationsAvailable], ledger[totalDonationsWithdrawn], ledger[totalDonationsCancelled], ledger[totalEtherEver], ledger[totalEtherNow], ledger[totalEtherWithdrawn], ledger[totalEtherCancelled], ledger[monthlyDonation]);
        LOG_ContractBalance(this.balance);
      
        ledger[patreonsCancelled] += 1;
        ledger[patreonsNow] -= 1;
        ledger[monthlyDonationsAvailable] -= monthsRemoved;
        ledger[totalDonationsCancelled] += monthsRemoved;
        ledger[totalEtherNow] -= refund;
        ledger[totalEtherCancelled] += refund;
        
        donators[patreonID].totalRemaining = 0;
        donators[patreonID].monthsRemaining = 0;
        
        msg.sender.transfer(refund);


        LOG_FullLedger(ledger[allPatreonsEver], ledger[patreonsNow], ledger[patreonsFinished], ledger[patreonsCancelled], ledger[totalDonationsEver], ledger[monthlyDonationsAvailable], ledger[totalDonationsWithdrawn], ledger[totalDonationsCancelled], ledger[totalEtherEver], ledger[totalEtherNow], ledger[totalEtherWithdrawn], ledger[totalEtherCancelled], ledger[monthlyDonation]);

        LOG_ContractBalance(this.balance);


        
    }
    
    
    
        //dont think this is needed, because there is only the contract balance that is held here. there is really no error fund, or any of the other funds
        // unless i wanted to make a Fee fund. but that is for the future :)
    function bookKeeping(uint8 _from, uint8 _to, uint _amount) internal {
        ledger[_from] -= uint(_amount);
        ledger[_to] += uint(_amount);
    }
    
    function checkIfPatreonsAreDoneDonating () internal returns (uint _patreonsDone) {
        
        uint patreonsDone;
        
        for (uint x = 0; x<donators.length; x++) {
            donators[x].totalRemaining -= donators[x].paymentPerMonth;
            donators[x].monthsRemaining -= 1;
            
            if (donators[x].monthsRemaining == 0){
                patreonsDone++;
            }
        }
        
        return patreonsDone;
            

        
        
    }
    
    //ledger here has things moved from being completed
    function creatorWithdrawMonthly() onlyCreator { //right now people only contribute for a 12 month term. I GUESS the user 
        
        //march 31 2020 = 1583020800
        //march 31 20201 = 1614556800
        //march 31 2024 = 1709251200
        
        //july 1st 2017, to test one month withdrawl = 1498867200;
        
        uint dynamicFirstOfMonth = 1498867200; //starts on August 1st, 2017
        
        uint secondsInOneMonth31 = 2678400; // aug, oct dec, jan, mar, may, july
        uint secondsInOneMonth30 = 2592000; //sept, nov, april, june
        uint secondsInOneMonth28 = 2419200; // feb
        uint secondsInOneMonth29 = 2505600; // feb 29 2020
        

        if (now > dynamicFirstOfMonth) { //accoridng to this, if guy is two months behind, he can only withdraw one at a time. will need to do 2 transactions
            //math to withdraw all money
            
            uint amountToWithdraw = ledger[patreonsNow]*ledger[monthlyDonation];
            
            ledger[monthlyDonationsAvailable] -= ledger[patreonsNow]; //if there were 5 patreons, 5 monthly donations were withdrawn! so minus that
            ledger[totalDonationsWithdrawn] += ledger[patreonsNow]; 
            
            ledger[totalEtherNow] -= amountToWithdraw;
            ledger[totalEtherWithdrawn] += amountToWithdraw;

            uint patreonsCompleted = checkIfPatreonsAreDoneDonating();
            
            ledger[patreonsNow] -= patreonsCompleted;
            ledger[patreonsFinished] += patreonsCompleted;
            
            LOG_ContractBalance(this.balance);
            creator.transfer(amountToWithdraw);
            LOG_ContractBalance(this.balance);
            
            
            LOG_FullLedger(ledger[allPatreonsEver], ledger[patreonsNow], ledger[patreonsFinished], ledger[patreonsCancelled], ledger[totalDonationsEver], ledger[monthlyDonationsAvailable], ledger[totalDonationsWithdrawn], ledger[totalDonationsCancelled], ledger[totalEtherEver], ledger[totalEtherNow], ledger[totalEtherWithdrawn], ledger[totalEtherCancelled], ledger[monthlyDonation]);

            
            //change dynamicFirstOfMonth, with math. then increment 
            if (monthlyCounter == 7 || monthlyCounter ==  9 || monthlyCounter == 11 || monthlyCounter == 0 || monthlyCounter == 2 || monthlyCounter == 4 || monthlyCounter == 6){
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
                if (now > leapYearCounter){
                    dynamicFirstOfMonth = dynamicFirstOfMonth + secondsInOneMonth29;
                    leapYearCounter += leapYearCycle;
                     monthlyCounter++;
                } else {
                    dynamicFirstOfMonth += secondsInOneMonth28;
                    monthlyCounter++;
                }
            }
        }
        
        
        
    }


    function creatorWithdrawFromContract() onlyCreator returns (uint) { //some reason it says oout of gas when i try to call this from creator .... hmmm
        //maybe it is beacuse the contract does not have any gas. and transferring takes a lot of gas. setOntTimeContribution works though!? i dont know :\
      
        //wouldnt make sense, creator is calling this. it is not an auto call from the contract. 
        LOG_Withdraw(creator.balance);
        creator.transfer(this.balance);
        LOG_Withdraw(creator.balance);
        
        return creator.balance;
    
  }


/*********************************************Helper Functions (or functions that are general to many contracts**************************************************************************/

/*

  function getTotalDonations() {
      
  }


  function getMonthlyDonations() {
      
  }



  function getContractBalance() {
      
  }
*/

  function () {} //fallback function. dont accept ether to this contract without calling the constructor function or others. this way, people dont accidentally burn their money


}





contract PatreonFactory {
    bytes32[] names;
    address[] newContracts;
    address[] originalCreators;
    
    address factoryAddress = this;
    
    event LOG_NewContractAddress (address theNewcontract, address theContractCreator);

    function createContract (bytes32 name) returns(address, bytes32, uint, address) {
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
    function getcontractAddressAtIndex(uint i) constant returns(address contractAddress) {
        return newContracts[i];
    }
    
    function getOriginalCreator(uint i) constant returns (address originalCreator) {
        return originalCreators[i];
    }
}





/*




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