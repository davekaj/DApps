pragma solidity ^0.4.4;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function Migrations() {
    owner = msg.sender;
  }

  function setCompleted(uint completed) restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}

// truffle requires you to have a migrations contract in order to use the migrations featute. so this must be an automatic contract. 

//reading the code it looks like it just keeps track of all past kmigrations and moves forward, which is what the docs explained,. nice 
