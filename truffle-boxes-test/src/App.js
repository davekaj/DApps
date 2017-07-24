import React, { Component } from 'react'
import SimpleStorageContract from '../build/contracts/SimpleStorage.json'
import getWeb3 from './utils/getWeb3'

import './css/oswald.css'
import './css/open-sans.css'
import './css/pure-min.css'
import './App.css'

/*

beatutiful. web3. is a state within the react app. this makes it so simple to call any of its functions. 

instantiate contract is a custom made function. it is caled within component will mount 

why isnt this motherfucker binding stuff!

how does it just require truffle contract? 

they take contract() which must be from truffle contract, and apply it to SimpleStorageContract

then they set that contract to a provided, which we get from the web3 state

deployed() deals with delpoying the contracts. this is a truffle thing too . note this is all truffle which doesnt seem like react 


simple storage .get and .set ARE CONTRACT FUNCTIONS! believe that 

so far, in dealing with my contracts, i have not seen them in jaavscript files. I have tested them with mocha inside of a truffle framework, and i have also debugged them with Remix on 
the web browser. but this is where web3 comes in. web3 is what links blockchain actions to js. BUT TRUFFLE comes with web3, so i have been ysing it hen i was running tests with it. all is good

the metamask example for metapay is simply just all web3 and javascript interacting with metamast directly. there is no contract at all. which makes me realize that no contract is needed
to do what i want to do. but oh well we will make it. because i am learning how to write contracts. not just do REACT AND JS

 */




class App extends Component {
  constructor(props) {
    super(props)

    this.state = {
      storageValue: 0,
      web3: null,
      yourAccount: "Could not connect to metamask",
      yourBalance: "same as above",
      nonce: 0
    }
  }


  componentWillMount() {
    // Get network provider and web3 instance.
    // See utils/getWeb3 for more info.

    getWeb3
      .then(results => {
        this.setState({
          web3: results.web3,
        })

        // Instantiate contract once web3 provided.
        this.instantiateContract()
        this.getUserAccountAndBalance();
        let nonce = this.getNonce();
        console.log(nonce);
        this.setState({
          nonce: nonce
        })
      })
      .catch(() => {
        console.log('Error finding web3.')
      })
  }


  getUserAccountAndBalance() {
    var account;
    var accountBalance;

    this.state.web3.eth.getAccounts((error, accounts) => {
      account = accounts[0];

      accountBalance = this.state.web3.eth.getBalance(account, (error, result) => {
        if (!error) {
          console.log(result)
          var goodNum = result.c[0] / (10000);
          var goodNumToString = goodNum.toString() + " ether";
          console.log(typeof (goodNum));
          this.setState({
            yourAccount: account,
            yourBalance: goodNumToString
          })
        }
        else {
          console.log(error);
        }

      })
    })
  }

  //a raw transactin is a transaction that is in raw buyes
  sendTransactionToFriend(friendsAccount, ether, gasPrice, gasLimit, nonce) {
    return (dispatch) => {
      let web3 = this.state.web3;
      let user = web3.eth.accounts[0];
      let wei = Math.pow(10, 18);
      let etherToWei = ether * wei;
      let gasPriceWei = gasPrice * Math.pow(10, 9);

      let rawTx = {
        nonce: `Ox${nonce.toString(16)}`,
        gasPrice: `Ox${gasPriceWei.toString(16)}`,
        gasLimit: `Ox${gasLimit.toString(16)}`,
        from: user,
        to: friendsAccount,
        value: `Ox${etherToWei.toString(16)}`
      };
      console.log('raw txn:', rawTx);
      web3.eth.sendTransaction(rawTx, (err, txHash) => {
        if (err) { console.log('Error sending txm:', err); }
      })
    }
  }



  getNonce() {
    let web3 = this.state.web3;
    let user = web3.eth.accounts[0];
    console.log(user);
    let nonce = web3.eth.getTransactionCount(user, (err, nonce) => {
      if (err) { console.log('Error getting nonce', err); }
    });
    console.log(nonce);
    return nonce;
  }

  /*
    getNonce() {
      return (dispatch) => {
        let web3 = this.state.web3;
        let user = web3.eth.accounts[0];
        web3.eth.getTransactionCount(user, (err, nonce) => {
          if (err) { console.log('Error getting nonce', err); }
        });
      }
    }
  */


  instantiateContract() {
    /*
     * SMART CONTRACT EXAMPLE
     *
     * Normally these functions would be called in the context of a
     * state management library, but for convenience I've placed them here.
     */

    const contract = require('truffle-contract') // oh okay this is just like import, i get it, but this would normally be a a JS file for state management (a library)
    const simpleStorage = contract(SimpleStorageContract)
    simpleStorage.setProvider(this.state.web3.currentProvider)

    // Declaring this for later so we can chain functions on SimpleStorage.
    var simpleStorageInstance

    // Get accounts.
    this.state.web3.eth.getAccounts((error, accounts) => {
      simpleStorage.deployed().then((instance) => {
        simpleStorageInstance = instance

        // Stores a given value, 5 by default.
        return simpleStorageInstance.set(5, { from: accounts[0] })
      }).then((result) => {
        // Get the value from the contract to prove it worked.
        return simpleStorageInstance.get.call(accounts[0])
      }).then((result) => {
        // Update state with the result.
        console.log(result);
        return this.setState({ storageValue: result.c[0] })
      })
    })
  }

  render() {
    return (
      <div className="App" >
        <nav className="navbar pure-menu pure-menu-horizontal">
          <a href="#" className="pure-menu-heading pure-menu-link">Send Ether to a Friend</a>
        </nav>

        <main className="container col-xs-12">
          <div className="full-page">
            <div className="title-and-description test-border">
              <h1 className="text-center">Send Ether Directly to a Friend</h1>
              <p>This Simple UX/UI of this website will let you easily send ether to a friend. Watch out for fishing websites.  </p>
              <h2>What does the smart contract actually do?</h2>
              <p>It connects to whichever site you are connected through with metamask, if you are on the normal web, or whatever mist is connected to. See below all the contract code:</p>
              <p>[INSERT CODE HERE, MAKE IT LOOK LIKE CODE HOW THEY DO ONLINE]</p>
              <p>Also I might try to get gas costs and estimated time based on gwei if i Can!</p>
              <p>The stored value is: {this.state.storageValue}</p>
            </div>
            <div className="send-Ether-App col-xs-6 test-border">
              <div className="bigger-text">If your account connects properly, you will see your account and balance below</div><br />
              <div>Your Account: {this.state.yourAccount}</div>
              <div>Your Balance: {this.state.yourBalance}</div>
              <br /><div className="bigger-text">Fill in the form below to send a transaction </div><br />
              <form>
                <div>Friends Account 	&nbsp;: <input type="text" name="friend" placeholder="Friends account" /></div>
                <div>Amount to Send	 : <input type="text" name="sendAmount" placeholder="Amount to Send in Ether" /> </div>
                <div>Gas to Send 	&nbsp;	&nbsp;	&nbsp;	&nbsp;   : <input type="text" name="gasToSend" placeholder="Gas" /> </div>
                <div>Gwei per gas 	&nbsp;	&nbsp;	&nbsp;  : <input type="text" name="gweiToSend" placeholder="Gwei" /></div>
              </form>
            </div>
            <div className="ether-image col-xs-5 test-border text-center">
              <img src="https://www.cryptodiggers.eu/eshop/image/data/ethereum.png" />
            </div>
          </div>
        </main>
      </div >
    );
  }
}

export default App
