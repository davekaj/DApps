import React, { Component } from 'react';
import { connect } from 'react-redux';
import { FormControl, FormGroup, Button, Row, Col } from 'react-bootstrap';
import { Promise } from 'bluebird';
import { metaPay } from '../actions/index'

class MetaPayComponent extends Component {
  constructor(props){
    super(props);
  }

  componentDidMount() {
    let { dispatch } = this.props;
    dispatch({ type: 'UPDATE_USD_AMT', result: 20. })
    dispatch(metaPay.getPrice())
    if (web3) {
      dispatch({ type: 'UPDATE_USER', result: web3.eth.accounts[0] })
      dispatch(metaPay.getNonce(web3))
      let provider = web3.version.network;
      dispatch({ type: 'UPDATE_WEB3_PROVIDER', result: provider })
    }
  }

  sendTxn() {
    let { dispatch, pay } = this.props;
    let to_save = {
      name: pay.name,
      address: pay.address,
      city: pay.city,
      country: pay.country
    };
    dispatch(metaPay.saveAddress(to_save))
    let num_eth = parseFloat(pay.usd_amt) / pay.eth_price;
    dispatch(metaPay.sendTxn(web3, num_eth, pay.nonce))
  }

  updateName(e) {
    dispatch({ type: 'UPDATE_NAME', result: e.target.value})
  }
  updateAddress(e) {
    dispatch({ type: 'UPDATE_ADDRESS', result: e.target.value})
  }
  updateCity(e) {
    dispatch({ type: 'UPDATE_CITY', result: e.target.value})
  }
  updateCountry(e) {
    dispatch({ type: 'UPDATE_COUNTRY', result: e.target.value})
  }

  renderMetamaskCheckout() {
    let { pay } = this.props;
    return (
      <Row>
      <Col md={4}></Col>
      <Col md={4}>
        <center>
        <h2>Checkout</h2>
        <h5>Horray! You're a Metamask user.</h5>
        <p>We'll give you the good stuff.</p>
        <div>
          <form>
            <br/>
            <FormGroup>
              <FormControl type="text" value={pay.name} onChange={this.updateName.bind(this)}/>
              Name
              <FormControl type="text" value={pay.address} onChange={this.updateAddress.bind(this)}/>
              Address
              <FormControl type="text" value={pay.city} onChange={this.updateCity.bind(this)}/>
              City
              <FormControl type="text" value={pay.country} onChange={this.updateCountry.bind(this)}/>
              Country
            </FormGroup>
          </form>
          <br/>
          <Button bsStyle="primary" bsSize="large" onClick={this.sendTxn.bind(this)}>
            Pay ${this.props.pay.usd_amt}
          </Button>
        </div>
        </center>
      </Col>
      </Row>
    );
  }

  renderCheckout(network_err) {
    let wrongNetwork = '';
    if (network_err) {
      wrongNetwork = <h5>We detect metamask, but you're on the wrong network. Please switch to Ethereum Main Net</h5>
    }
    return (
      <Row>
      <Col md={4}></Col>
      <Col md={4}><center>
        {wrongNetwork}
        <h2>Checkout</h2>
        <h5>What a boring checkout. Too bad you aren't using Metamask.</h5>
        <div>
          <form>
            <br/>
            <FormGroup>
              <FormControl />
              Name
              <FormControl />
              Address
              <FormControl />
              City
              <FormControl />
              Country
            </FormGroup>
          </form>
          <br/>
          <Button bsStyle="primary" bsSize="large" block>Pay ${this.props.pay.usd_amt}</Button>
        </div>
      </center></Col>
      </Row>
    );
  }

  render(){
    let { pay } = this.props;
    if (web3 && pay.web3_provider == 1) {
      return this.renderMetamaskCheckout();
    } else if (web3) {
      return this.renderCheckout(true);
    } else {
      return this.renderCheckout();
    }
  }

}

const mapStoreToProps = (store) => {
  return {
    pay: store.metaPay
  };
}

const MetaPay = connect(mapStoreToProps)(MetaPayComponent);

export default MetaPay;
