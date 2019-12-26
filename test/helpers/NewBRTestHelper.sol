pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../../contracts/NewBlockRelay.sol";

/**
 * @title Test Helper for the new block Relay contract
 * @dev The aim of this contract is:
 * 1. Raise the visibility modifier of new block relay contract functions for testing purposes
 * @author Witnet Foundation
 */


contract NewBRTestHelper is NewBlockRelay {
  NewBlockRelay br;
  uint256 timestamp;
  uint256 witnetGenesis;

  constructor (uint256 _witnetGenesis, uint256 _epochSeconds) NewBlockRelay(_witnetGenesis, _epochSeconds) public {}

  event Winner(uint256 _winner);
  event EpochStatus(string _epochStatus);


  function updateEpoch() public view returns (uint256) {
    return currentEpoch;
  }

  // Sets the current epoch to be the next
  function nextEpoch() public {
    currentEpoch = currentEpoch + 1;
  }

  function setEpoch(uint256 _epoch) public returns (uint256) {
    currentEpoch = _epoch;
  }

  function setAbsIdentities(uint256 _identitiesNumber) public returns (uint256) {
    activeIdentities = _identitiesNumber;
  }

  function finalresult(uint256 _previousHash) public returns (uint256) {
    postNewBlock(
      winnerId,
      winnerEpoch,
      winnerDrMerkleRoot,
      winnerTallyMerkleRoot,
      _previousHash);
  }

  function getCandidates() public view returns (uint256) {
    uint256 candidate = candidates[0];
    return candidate;
  }

  function winnerProposed(uint256 _epoch) public returns (uint256) {
    return epochCandidates[_epoch].winner;
  }

  function checkStatusPending() public returns (bool) {
    string memory pending = "Pending";
    if (keccak256(abi.encodePacked((epochStatus))) == keccak256(abi.encodePacked((pending)))) {
      return true;
    }
  }

  /*function getWinnerProposal() public returns (uint256) {
    emit Winner(epochCandidates[currentEpoch].winner);
    return epochCandidates[currentEpoch].winner;
  }*/
}