/**************************************************************************************************************************
Note that for it to work on testnet, instead of .deployed, it should be .at() for factory
dont forget to truffle compile and truffle migrate 

***************************************************************************************************************************/
import React, { Component } from 'react'
import PatreonFactory from '../build/contracts/PatreonFactory.json'
import getWeb3 from './utils/getWeb3'
import SinglePatreon from '../build/contracts/SinglePatreon.json'
import './css/oswald.css'
import './css/open-sans.css'
import './css/pure-min.css'
import './App.css'

const contract = require('truffle-contract')
const singleContract = contract(SinglePatreon)
const patreonFactory = contract(PatreonFactory)



class App extends React.Component {
  constructor(props) {
    super(props)

    this.state = {
      contractNameArray: [],
      contractAddressArray: [],
      originalCreatorArray: [],
      combinedArrays: [],
      web3: null,
      contractPickedByDonator: "",
      contractName: "",
      childVisible: false,
      patreonFactoryAddress: "",
    }

    this.onInput = this.onInput.bind(this);
    this.getArraysFromFactory = this.getArraysFromFactory.bind(this);
    
  }

  //mounts, gets web3, calls getArrays
  componentWillMount() {
    // Get network provider and web3 instance.
    // See utils/getWeb3 for more info.

    getWeb3
      .then(results => {
        this.setState({
          web3: results.web3
        })
        this.getArraysFromFactory();
      })
      .catch(() => {
        console.log('Error finding web3.')
      })
  }

  //any user who injects web3 can make a contract to get donations with this function call
  //note that 
  createPatreonContract() {
    patreonFactory.setProvider(this.state.web3.currentProvider)

    var patreonInstance

    // Get accounts.
    this.state.web3.eth.getAccounts((error, accounts) => {
      patreonFactory.deployed().then((instance) => {
        patreonInstance = instance
        return patreonInstance.createContract(this.state.contractName, { from: accounts[0] })
      }).then((result) => {
        console.log(result);// note that this returns a general block tx, recipt, and logs array. does NOT return what solidity function returns
        this.getArraysFromFactory();        
        //code to do an EVENT WATCH. Need more of these
        var event = patreonInstance.LOG_NewContractAddress()
        event.watch(function (error, result) {
          if (!error)
            console.log(result); //some readon I keep getting TWO identical of these printed

        })
      })
    })
  }

  //function to get the three arrays of info from factory
  getArraysFromFactory() {
    patreonFactory.setProvider(this.state.web3.currentProvider)
    var patreonInstance
    var _contractNameArray;
    var _contractAddressArray;
    var _originalCreatorArray;
    var _factoryAddress;

    this.state.web3.eth.getAccounts((error, accounts) => {
      patreonFactory.deployed().then((instance) => {
        patreonInstance = instance
        _factoryAddress = patreonInstance.address;
        //get the name array
        return patreonInstance.getNameArray.call({ from: accounts[0] })
      }).then((result) => {
        _contractNameArray = result;
        //loop through the name array array returned from contract and parse it to human readable
        for (var i = 0; i < _contractNameArray.length; i++) {
          _contractNameArray[i] = this.state.web3.toAscii(_contractNameArray[i]).replace(/\u0000/g, ""); //this regex is needed because it returns a bunch of 0's from the contract
        }
        //get the address array
        return patreonInstance.getContractAddressArray.call({ from: accounts[0] })
      }).then((result) => {
        _contractAddressArray = result;
        //get the creator array
        return patreonInstance.getOriginalCreatorArray.call({ from: accounts[0] });
      }).then((result) => {
        _originalCreatorArray = result;



        this.setState({
          contractNameArray: _contractNameArray,
          contractAddressArray: _contractAddressArray,
          originalCreatorArray: _originalCreatorArray,
          patreonFactoryAddress: _factoryAddress,
        })
        this.combineArrays(); // don't need to actually return this. so i didnt
      })
    })
  }

  //function to combine the arrays into an array of arrays to display all contracts created
  combineArrays() {
    let combinedContractArrays = [];
    let _contractNameArray = this.state.contractNameArray;
    let _contractAddressArray = this.state.contractAddressArray;
    let _originalCreatorArray = this.state.originalCreatorArray;

    for (let i = 0; i < _contractNameArray.length; i++) {
      let contractInfo = [];
      contractInfo.push(_contractNameArray[i]);
      contractInfo.push(_contractAddressArray[i]);
      contractInfo.push(_originalCreatorArray[i]);
      combinedContractArrays.push(contractInfo);
    };
    console.log(combinedContractArrays);
    this.setState({
      combinedArrays: combinedContractArrays
    })

  }

  //just sets state to pick a contract. A little buggy at the start, it starts off on first contract created but it hasn't actually been put into the state yet
  donatorChoosesContract(e) {
    let selectedContract = e.target.value;
    this.setState({
      contractPickedByDonator: selectedContract,
      childVisible: true,
    })
  }

  onInput(e) {
    this.setState({
      contractName: e.target.value,
    })
  }


  render() {
    let combinedArrayDropdown = this.state.combinedArrays;
    let dropdownContracts = combinedArrayDropdown.map((contract, i) => {
      return (
        <option key={i} value={contract[1]} >Name: {contract[0]} &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Contract Address: {contract[1]}</option>
      )
    })
    return (
      <div className="App">
        <nav className="navbar pure-menu pure-menu-horizontal">
          <a href="#" className="">Patreon Donation dApp with Truffle and React</a>
        </nav>
        <br />
        <main className="container">
          <div className="test-border col-xs-12 col-sm-6">
            <h1>Patreon Factory Contract ({this.state.patreonFactoryAddress}) Creator Choices</h1 ><hr />
            <div className="row">
              <div className="col-xs-5">Click the button to use the PatreonFactory contract to create your own Patreon contract to accept donations.</div>
              <button className="col-xs-2 btn btn-warning" onClick={() => { this.createPatreonContract() }}>Create</button>
              <input className="col-lg-offset-1 col-xs-3 " type="text" value={this.state.value} onChange={this.onInput} placeholder="Enter contract name"></input>
            </div>
          </div>
          <br />
          <div className="test-border col-xs-12 col-sm-6">
            <h1>Patreon Factory Contract Donator Choices</h1><hr />
            <div>Choose the contract you want to interact with: &nbsp;
                <select onClick={(e) => { this.donatorChoosesContract(e) }}>
                <option>Select the contract from this Dropdown Menu</option>
                {dropdownContracts}
              </select>
            </div>
          </div>
          <div>
            {this.state.childVisible ?
              <SinglePatreonContractUI chosenContract={this.state.contractPickedByDonator}></SinglePatreonContractUI> : null
            }
          </div>
        </main>
      </div>
    );
  }
}

class SinglePatreonContractUI extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      web3: null,
      singleDonationFeeBigNumber: {},
      singleDonationFeeBase: 0,
      singleDonationFeeExponent: 0,
      contractBalance: {},
      contractBalanceEtherRounded: 0,
      monthlyAmount: {},
      monthlyAmountEtherRounded: 0,
      setOneTimeValue: 0,
      setMonthlyValue: 0,
    }
    this.setOneTimeContribution = this.setOneTimeContribution.bind(this);
    this.getOneTimecontribution = this.getOneTimecontribution.bind(this);
    this.getContractBalance = this.getContractBalance.bind(this);
    this.onInputSinglePatreon = this.onInputSinglePatreon.bind(this);
  }

  //haven't figured out how to only have to do this once. but its fine
  componentWillMount() {
    getWeb3
      .then(results => {
        this.setState({
          web3: results.web3
        })
      })
      .catch(() => {
        console.log('Error finding web3.')
      })
  }

  //allows creator to set a one time contribution amount
  setOneTimeContribution() {
    singleContract.setProvider(this.state.web3.currentProvider)
    var contractInstance;

    this.state.web3.eth.getAccounts((error, accounts) => {
      singleContract.at(this.props.chosenContract).then((instance) => {
        contractInstance = instance;
        let oneTimeCont = this.state.web3.toWei(this.state.setOneTimeValue, 'ether');
        return contractInstance.setOneTimeContribution(oneTimeCont, { from: accounts[0] });
      }).then((result) => {
        console.log(result);
      })
    })
  }

  //allows user to set a monthly contribution amount. note that a years worth must be sent in ether
  setMonthly() {
    singleContract.setProvider(this.state.web3.currentProvider)
    var contractInstance;

    this.state.web3.eth.getAccounts((error, accounts) => {
      singleContract.at(this.props.chosenContract).then((instance) => {
        contractInstance = instance;
        let oneTimeCont = this.state.web3.toWei(this.state.setMonthlyValue, 'ether');
        return contractInstance.setMonthlyContribution(oneTimeCont, { from: accounts[0] });
      }).then((result) => {
        console.log(result);
      })
    })
  }

  //allows donator to see what is required for them to donate . maybe have this autoload when contract is selected
  //note that big number is returned
  getOneTimecontribution() {
    singleContract.setProvider(this.state.web3.currentProvider)
    var contractInstance;

    this.state.web3.eth.getAccounts((error, accounts) => {
      singleContract.at(this.props.chosenContract).then((instance) => {
        contractInstance = instance;
        return contractInstance.getOneTimecontribution.call();
      }).then((result) => {
        //console.log(result);
        //console.log(result.s);
        //console.log(result.e);
        this.setState({
          singleDonationFeeBigNumber: result,
          singleDonationFeeBase: result.s,
          singleDonationFeeExponent: result.e,
        })
      })
    })
  }

  //this function directly sends ether to the account. the ether never stays in the contract account
  sendOneTimeContribution() {
    singleContract.setProvider(this.state.web3.currentProvider)
    var contractInstance;

    this.state.web3.eth.getAccounts((error, accounts) => {
      singleContract.at(this.props.chosenContract).then((instance) => {
        contractInstance = instance;
        let sendAmount = this.state.web3.toWei(this.state.setOneTimeValue, 'ether');
        return contractInstance.oneTimeContribution({ value: sendAmount, from: accounts[0] });
      }).then((result) => {
        console.log(result);
      })
    })
  }

  //send a years worth of monthly contributions to a patreon
  sendMonthlyContribution() {
    singleContract.setProvider(this.state.web3.currentProvider)
    var contractInstance;

    this.state.web3.eth.getAccounts((error, accounts) => {
      singleContract.at(this.props.chosenContract).then((instance) => {
        contractInstance = instance;
        let sendAmount = this.state.web3.toWei(this.state.setMonthlyValue, 'ether');
        return contractInstance.monthlyContribution({ value: sendAmount, from: accounts[0] });
      }).then((result) => {
        console.log(result);
      })
    })
  }

  //when done, it should increase the creators eth balance, and lower contract balance. lets creator withdraw
  creatorWithdraw() {
    singleContract.setProvider(this.state.web3.currentProvider)
    var contractInstance;

    this.state.web3.eth.getAccounts((error, accounts) => {
      singleContract.at(this.props.chosenContract).then((instance) => {
        contractInstance = instance;
        return contractInstance.creatorWithdrawMonthly();
      }).then((result) => {
        console.log(result);
      })
    })
  }

  //this one takes more gas than metamask offered. had to go from 100K to 1M
  patreonCancle() {
    singleContract.setProvider(this.state.web3.currentProvider)
    var contractInstance;

    this.state.web3.eth.getAccounts((error, accounts) => {
      singleContract.at(this.props.chosenContract).then((instance) => {
        contractInstance = instance;
        return contractInstance.patreonCancleMonthly();
      }).then((result) => {
        console.log(result);
      })
    })
  }

  //lets donator see monthly donation requirements. should be autoloaded
  getMonthly() {
    singleContract.setProvider(this.state.web3.currentProvider)
    var contractInstance;

    this.state.web3.eth.getAccounts((error, accounts) => {
      singleContract.at(this.props.chosenContract).then((instance) => {
        contractInstance = instance;
        return contractInstance.getMonthlyDonationAmount();
      }).then((result) => {
        //console.log(result);
        // console.log(result.c[0] * 0.0001);
        this.setState({
          monthlyAmount: result,
          monthlyAmountEtherRounded: result.c[0] * 0.0001
        })
      })
    })
  }

  //this is built wrong. Anything ether rounded may not be 100% accurate 
  getContractBalance() {
    singleContract.setProvider(this.state.web3.currentProvider)
    var contractInstance;

    this.state.web3.eth.getAccounts((error, accounts) => {
      singleContract.at(this.props.chosenContract).then((instance) => {
        contractInstance = instance;
        return contractInstance.getContractBalance({ from: accounts[0] });
      }).then((result) => {
        console.log(result);
        console.log(result.c[0] * 0.0001);
        this.setState({
          contractBalance: result,
          contractBalanceEtherRounded: result.c[0] * 0.0001
        })
      })
    })
  }

  onInputSinglePatreon(e) {
    if (e.target.id === "singleDonation") {
      this.setState({
        setOneTimeValue: e.target.value,
      })
    } else if (e.target.id === "monthlyDonation") {
      this.setState({
        setMonthlyValue: e.target.value
      })
    }
  }

  render() {

    return (
      <div>
        <br />
        <div className="chosen-Contract test-border col-xs-12 col-sm-6">
          <h3> Chosen Contract: {this.props.chosenContract}</h3>
        </div>
        <br />

        <div className="test-border col-xs-12 col-sm-6">
          <h1>Single Patreon Contract Creator Choices</h1><hr />

          <div className="row">
            <div className="col-xs-5">Set your one time contribution fee in Ether:</div>
            <button className="col-xs-2 btn btn-warning" onClick={() => { this.setOneTimeContribution() }}>Set</button>
            <input className="col-lg-offset-1 col-xs-3" id="singleDonation" type="text" value={this.state.value} onChange={this.onInputSinglePatreon} placeholder="Enter single donation"></input>
          </div>

          <div className="row">
            <div className="col-xs-5">Set your one Monthly contribution fee in Ether:</div>
            <button className="col-xs-2 btn btn-warning" onClick={() => { this.setMonthly() }}>Set</button>
            <input className="col-lg-offset-1 col-xs-3" id="monthlyDonation" type="text" value={this.state.value} onChange={this.onInputSinglePatreon} placeholder="Enter monthly donation"></input>
          </div>

          <div className="row">
            <div className="col-xs-5">Get the Contract Balance:</div>
            <button className="col-xs-2  btn btn-primary" onClick={() => { this.getContractBalance() }}>Get</button>
            <div className="col-xs-5">The contract balance is {this.state.contractBalanceEtherRounded} ether</div>
          </div>

          <div className="row">
            <div className="col-xs-5">Creator withdraw:</div>
            <button className="col-xs-2  btn btn-warning" onClick={() => { this.creatorWithdraw() }}>Withdraw</button>
          </div>

        </div>
        <br />

        <div className="test-border col-xs-12 col-sm-6">
          <h1>Single Patreon Contract Donator Choices</h1><hr />
          <div className="row">
            <div className="col-xs-5">See the one time fee to see if you want to pay:</div>
            <button className="col-xs-2 btn btn-primary" onClick={() => { this.getOneTimecontribution() }}>Get Fee</button>
            <div className="col-xs-5">The fee is : {this.state.singleDonationFeeBase * Math.pow(10, this.state.singleDonationFeeExponent)} wei</div>
          </div>
          <div className="row">
            <div className="col-xs-5">See the yearly amount you'd pay, which is released each month:</div>
            <button className="col-xs-2 btn btn-primary" onClick={() => { this.getMonthly() }}>Get Monthly</button>
            <div className="col-xs-5">The yearly amount is: {this.state.monthlyAmountEtherRounded} Ether. Monthly that is {this.state.monthlyAmountEtherRounded / 12} ether</div>
          </div>
          <div className="row">
            <div className="col-xs-5">Send one time contibution:</div>
            <button className="col-xs-2 btn btn-warning" onClick={() => { this.sendOneTimeContribution() }}>Send</button>
            <div className="col-xs-5">IF YOU CLICK THIS YOU WILL SEND AWAY  {this.state.monthlyAmountEtherRounded /12 } Ether</div>

          </div>
          <div className="row">
            <div className="col-xs-5">Send monthly contibution:</div>
            <button className="col-xs-2 btn btn-warning" onClick={() => { this.sendMonthlyContribution() }}>Send</button>
            <div className="col-xs-5">IF YOU CLICK THIS YOU WILL SEND AWAY  {this.state.monthlyAmountEtherRounded} Ether</div>

          </div>
          <div className="row">
            <div className="col-xs-5">Cancle your monthly contibution:</div>
            <button className="col-xs-2 btn btn-danger" onClick={() => { this.patreonCancle() }}>Cancle</button>
          </div>
        </div>
      </div>
    );
  }
}

export default App


/*
What do I want to build?

Creator
- get his contract name and number and his eth account to hand out to people
- has its own page (or for now 1 page)

  SinglePatreon Contract

Donator
- can easaily search for the contract they wanna donate too

  Single Patreon Contract
  - has its own page (or for now 1 page)


Testing
- testing should be checking rare cases, and interacting with multiple accounts
- because it would be too cumbersome for me to register 5 accounts and cancle a few
- this can be done in remix to an extent and it has been done, but some deeper should be done here

Learning about solidity
- so it turns out that accounts[0] will always refer to just the account taht web3 has injectsed
- so that means in metamask, whatever account i am using, whether its 0,1,2,3,4,5, on testrpc.
-it will register as 0
- makes sense for real deployment, which is good
- pretty sure default is just account 0 so I should be working with that 


Learning about the dev environment 
- when you update contract, you need to compile the contract and migrate. then prob best to
  reset the testnet, as well as the react front end. Then you should also lock meta mask,
  unlock it, and then refresh the page. Fun!


Bugs
- when page is refreshed, this.state.setMonthlyValue and this.state.setSingleDonation are both back to 0, so there is no msg.value with Send Buttons. 
 


*/