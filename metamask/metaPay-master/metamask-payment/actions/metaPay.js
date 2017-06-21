import Promise from 'bluebird';
import 'whatwg-fetch'

export default class metaPay {
  constructor (options) {
    this.owner_address = options.owner_address || '0xF70d67F47444DD538AB95DdC14ab15B1908CB0d9';
  }

  // Get price of Ether from GDAX
  getPrice(dispatch) {
    return (dispatch) => {
      var url = "https://api.gdax.com/products/ETH-USD/ticker";
      fetch(url)
      .then((response) => {
        return response.text()
      })
      .then((body) => {
        console.log('body', JSON.parse(body))
        if (body) {
          let p = JSON.parse(body).price;
          dispatch({ type: 'UPDATE_ETH_PRICE', result: parseFloat(p) });
        }
      })
      .catch((er) => {
        console.log('Error getting price: ', err)
      })
    }
  }

  getNonce(web3) {
    return (dispatch) => {
      let user = web3.eth.accounts[0];
      web3.eth.getTransactionCount(user, (err, nonce) => {
        dispatch({ type: 'UPDATE_NONCE', result: nonce })
        if (err) { console.log('Error getting nonce', err); }
      });
    }
  }

  saveAddress(data) {
    return (dispatch) => {
      console.log('Saving address:', data);
      // Save the address
    }
  }


  sendTxn(web3, ether, nonce) {
    return (dispatch) => {
      let user = web3.eth.accounts[0];
      let wei = ether * Math.pow(10, 18);
      let gasPrice = 3 * Math.pow(10, 9);
      let gasLimit = 30000;
      let rawTx = {
        nonce: `0x${nonce.toString(16)}`,
        gasPrice: `0x${gasPrice.toString(16)}`,
        gasLimit: `0x${gasLimit.toString(16)}`,
        from: user,
        to: this.owner_address,
        value: `0x${wei.toString(16)}`
      };
      console.log('raw txn', rawTx)
      web3.eth.sendTransaction(rawTx, (err, txHash) => {
        if (err) { console.log('Error sending txn:', err); }
        // Save the transaction hash
      })
    }
  }



}
