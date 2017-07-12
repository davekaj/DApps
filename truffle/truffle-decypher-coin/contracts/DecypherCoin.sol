pragma solidity ^0.4.4;

//import "./ConvertLib.sol";

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!
contract DecypherCoin {

  // ERC20 State
  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowances;
  uint256 public totalSupply;

  // Human State
  string public name;
  uint8 public decimals;
  string public symbol;
  string public version;

  // Minter State
  address public centralMinter;

  // Backed By Ether State
  uint256 public buyPrice;
  uint256 public sellPrice;

  // Modifiers
  modifier onlyMinter {
    if (msg.sender != centralMinter) throw;
    _;
  }

  // ERC20 Events
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  // Constructor
  function DecypherCoin(/*uint256 _initialAmount*/) {
    uint256 _initialAmount = 10000;
    balances[msg.sender] = _initialAmount;
    totalSupply = _initialAmount;
    centralMinter = msg.sender;
    name = "DecypherCoin";
    decimals = 18;
    symbol = "DCY";
    version = "0.1";
  }

  // ERC20 Methods
  function balanceOf(address _address) constant returns (uint256 balance) {
    return balances[_address];
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowances[_owner][_spender];
  }

  function transfer(address _to, uint256 _value) returns (bool success) {
    if(balances[msg.sender] < _value) throw;
    if(balances[_to] + _value < balances[_to]) throw;
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowances[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _owner, address _to, uint256 _value) returns (bool success) {
    if(balances[_owner] < _value) throw;
    if(balances[_to] + _value < balances[_to]) throw;
    if(allowances[_owner][msg.sender] < _value) throw;
    balances[_owner] -= _value;
    balances[_to] += _value;
    allowances[_owner][msg.sender] -= _value;
    Transfer(_owner, _to, _value);
    return true;
  }

  // Minter Functions
  function mint(uint256 _amountToMint) onlyMinter {
    balances[centralMinter] += _amountToMint;
    totalSupply += _amountToMint;
    Transfer(this, centralMinter, _amountToMint);
  }

  function transferMinter(address _newMinter) onlyMinter {
    centralMinter = _newMinter;
  }

  // Backed By Ether Methods
  // Must create the contract so that it has enough Ether to buy back ALL tokens on the market, or else the contract will be insolvent and users won't be able to sell their tokens
  function setPrices(uint256 _newSellPrice, uint256 _newBuyPrice) onlyMinter {
    sellPrice = _newSellPrice;
    buyPrice = _newBuyPrice;
  }

  function buy() payable returns (uint amount) {
    amount = msg.value / buyPrice;
    if(balances[centralMinter] < amount) throw;            // Validate there are enough tokens minted
    balances[centralMinter] -= amount;
    balances[msg.sender] += amount;
    Transfer(centralMinter, msg.sender, amount);
    return amount;
  }

  function sell(uint _amount) returns (uint revenue) {
    if (balances[msg.sender] < _amount) throw;            // Validate sender has enough tokens to sell
    balances[centralMinter] += _amount;
    balances[msg.sender] -= _amount;
    revenue = _amount * sellPrice;
    if (!msg.sender.send(revenue)) {
      throw;
    } else {
      Transfer(msg.sender, centralMinter, _amount);
      return revenue;
    }
  }

}