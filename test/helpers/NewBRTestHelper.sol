pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../../contracts/NewBlockRelay.sol";
import "../../contracts/ActiveBridgeSetLib.sol";

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
  uint256 firstBlock;

  using ActiveBridgeSetLib for ActiveBridgeSetLib.ActiveBridgeSet;

  constructor (uint256 _witnetGenesis, uint256 _epochSeconds, uint256 _firstBlock)
  NewBlockRelay(_witnetGenesis, _epochSeconds, _firstBlock) public {}

  event Winner(uint256 _winner);
  event EpochStatus(string _epochStatus);

  function pushActivity(uint256 _blockNumber) public {
    //_blockNumber = block.number;
    address _address = msg.sender;
    abs.pushActivity(_address, _blockNumber);
  }

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

  function setPreviousEpochFinalized() public {
    epochFinalizedBlock[currentEpoch - 2].status = "Finalized";
  }

  function getVote(
    uint256 _blockHash,
    uint256 _epoch,
    uint256 _drMerkleRoot,
    uint256 _tallyMerkleRoot,
    uint256 _previousVote) public returns(uint256)
    {
    uint256 vote = uint256(
      sha256(
        abi.encodePacked(
      _blockHash,
      _epoch,
      _drMerkleRoot,
      _tallyMerkleRoot,
      _previousVote)));

    return vote;

  }

  function getBlockHash(uint256 _epoch) public  returns (uint256) {
    uint256 blockHash = epochFinalizedBlock[_epoch].winningVote.blockHash;
    return blockHash;
  }

  function getCandidates() public view returns (uint256) {
    return candidates.length;
  }

  function checkStatusPending() public returns (bool) {
    string memory pending = "Pending";
    //emit EpochStatus(epochStatus[currentEpoch-2])
    if (keccak256(abi.encodePacked((epochFinalizedBlock[currentEpoch - 2].status))) == keccak256(abi.encodePacked((pending)))) {
      return true;
    }
  }

  function checkStatusFinalized() public returns (bool) {
    string memory finalized = "Finalized";
    //emit EpochStatus(epochStatus[currentEpoch-2])
    if (keccak256(abi.encodePacked((epochFinalizedBlock[currentEpoch - 2].status))) == keccak256(abi.encodePacked((finalized)))) {
      return true;
    }
  }

}