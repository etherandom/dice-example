import "api/etherandom.sol";

contract Dice is etherandomized {
  struct Roll {
    address bettor;
    bytes32 clientSeed;
  }

  address owner;
  uint pendingAmount;
  mapping (bytes32 => Roll) pendingSeed;
  mapping (bytes32 => Roll) pendingExec;
  mapping (bytes32 => bytes32) serverSeedHashes;

  function Dice() {
    owner = msg.sender;
  }

  function getAvailable() returns (uint _available) {
    return this.balance - pendingAmount;
  }

  function roll() {
    rollWithSeed("");
  }

  function rollWithSeed(bytes32 clientSeed) {
    if ( (msg.value != 1) || (getAvailable() < 2)) throw;
    bytes32 _id = etherandomSeed();
    pendingSeed[_id] = Roll({bettor: msg.sender, clientSeed: clientSeed});
    pendingAmount = pendingAmount + 2;
  }

  function onEtherandomSeed(bytes32 _id, bytes32 serverSeedHash) {
    if (msg.sender != etherandomCallbackAddress()) throw;
    Roll roll = pendingSeed[_id];
    bytes32 _execID = etherandomExec(serverSeedHash, roll.clientSeed, 100);
    pendingExec[_execID] = roll;
    serverSeedHashes[_execID] = serverSeedHash;
    delete pendingSeed[_id];
  }

  function onEtherandomExec(bytes32 _id, bytes32 serverSeed, uint randomNumber) {
    if (msg.sender != etherandomCallbackAddress()) throw;
    Roll roll = pendingExec[_id];
    bytes32 serverSeedHash = serverSeedHashes[_id];

    pendingAmount = pendingAmount - 2;

    if (etherandomVerify(serverSeedHash, serverSeed, roll.clientSeed, 100, randomNumber)) {
      if (randomNumber < 50) roll.bettor.send(2);
    } else {
      roll.bettor.send(1);
    }
    
    delete serverSeedHashes[_id];
    delete pendingExec[_id];
  }
}
