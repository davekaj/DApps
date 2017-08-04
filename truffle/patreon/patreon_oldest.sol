pragma solidity ^0.4.12;


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
    uint leapYearCounter = 1583020800;
    uint constant leapYearCycle = 126230400;//this number is 4 years plus a day, and it reoccuring on a consistent basis
    uint contractBalance = this.balance;

    
    //accounting stuff
    uint[13] public ledger;
    
    uint constant allPatreonsEver = 0; // 10
    uint constant patreonsNow = 1;  // 10 still
    uint constant patreonsFinished = 2; // 0
    uint constant patreonsCancelled = 3; //0
    
    uint constant totalDonationsEver = 4; //in months. so 120 for ten people at a year
    uint constant monthlyDonationsAvailable = 5; //113
    uint constant totalDonationsWithdrawn = 6; //7
    uint constant totalDonationsCancelled = 7; //0 
    
    uint constant totalEtherEver = 8; // 10 
    uint constant totalEtherNow = 9;  // ~8.5 ether
    uint constant totalEtherWithdrawn = 10; // ~1.5 ether
    uint constant totalEtherCancelled = 11; //0
    
    uint constant monthlyDonation = 12; // 0.083, but do i need this constant? 
    
    
    modifier onlyCreator {if (msg.sender != creator) revert(); _; }
    modifier onlyPatreons {if (msg.sender == creator) revert(); _;}
    
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
    
    mapping (address => uint[]) public donationID; //one address could submit multiple yearly donations if they want. would have to add donationID into here i think
    
    mapping (address => donationData) public patreonDonations; //i think this is needed for lookup of when someone wants to cancle to make that simple. lets keep it

    
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
        
        donationData memory pd = patreonDonations[msg.sender];
        
        pd.donator = msg.sender;
        pd.totalDonationStart = msg.value;
        pd.totalRemaining = msg.value;
        pd.monthsRemaining = 12;
        pd.paymentPerMonth = msg.value/pd.monthsRemaining;
        
        donators.push(pd);
        
        ledger[monthlyDonation] = pd.paymentPerMonth; //right now 0.083. but it could be changed, if i let users pick months. but it gets more difficult. MVP
        
        ledger[allPatreonsEver] += 1 ether;
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
    function patreonCancleMonthly() {
        
        //can easily call this one, because the address that calls it can only reference its own struct. 

        //the problem with this one is that, each individual patreon has to have their struct update when a new month happens. 
        
        // which just means that that will have to be a part of the withdraw function
        
        //it should be static though. and if a creator hasnt withdrwan their funds yet then they will get back their money even though they shouldnt have
        
        // this will also have to alter state variables
        
        
        //XXXXtry doing the memory thing
        
        LOG_ShowAllMonthlyDonationsOneUser ( patreonDonations[msg.sender].totalDonationStart,  patreonDonations[msg.sender].totalRemaining,  patreonDonations[msg.sender].monthsRemaining,  patreonDonations[msg.sender].paymentPerMonth,  patreonDonations[msg.sender].donator);
        
        uint refund =  patreonDonations[msg.sender].totalRemaining; //********THIS ENDS UP BEING 0!!! WHY!!! CHECK!
        
        
       
      //  if (refund == 0) revert();
       
        uint monthsRemoved = patreonDonations[msg.sender].monthsRemaining;
       
        LOG_FullLedger(ledger[allPatreonsEver], ledger[patreonsNow], ledger[patreonsFinished], ledger[patreonsCancelled], ledger[totalDonationsEver], ledger[monthlyDonationsAvailable], ledger[totalDonationsWithdrawn], ledger[totalDonationsCancelled], ledger[totalEtherEver], ledger[totalEtherNow], ledger[totalEtherWithdrawn], ledger[totalEtherCancelled], ledger[monthlyDonation]);
        LOG_ContractBalance(this.balance);
      
        ledger[patreonsCancelled] += 1;
        ledger[patreonsNow] -= 1;
        ledger[monthlyDonationsAvailable] -= monthsRemoved;
        ledger[totalDonationsCancelled] += monthsRemoved;
        ledger[totalEtherNow] -= refund;
        ledger[totalEtherCancelled] += refund;
        
        patreonDonations[msg.sender].totalRemaining = 0;
        patreonDonations[msg.sender].monthsRemaining = 0;
        
        msg.sender.transfer(refund);


        LOG_FullLedger(ledger[allPatreonsEver], ledger[patreonsNow], ledger[patreonsFinished], ledger[patreonsCancelled], ledger[totalDonationsEver], ledger[monthlyDonationsAvailable], ledger[totalDonationsWithdrawn], ledger[totalDonationsCancelled], ledger[totalEtherEver], ledger[totalEtherNow], ledger[totalEtherWithdrawn], ledger[totalEtherCancelled], ledger[monthlyDonation]);


        
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

  function ()  {} //fallback function. dont accept ether to this contract without calling the constructor function or others. this way, people dont accidentally burn their money


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





