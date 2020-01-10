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

  constructor (uint256 _witnetGenesis, uint256 _epochSeconds, uint256 _firstBlock) NewBlockRelay(_witnetGenesis, _epochSeconds, _firstBlock) public {}

  event Winner(uint256 _winner);
  event EpochStatus(string _epochStatus);


  // Addresses to be added to the ABS
  address[] addresses = [
    address(0x01),
    address(0x02),
    address(0x03),
    address(0x04)
  ];

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

  /*function finalresult(uint256 _previousHash) public returns (uint256) {
    postNewBlock(
      winnerId,
      winnerEpoch,
      winnerDrMerkleRoot,
      winnerTallyMerkleRoot,
      _previousHash);
  }*/

  function setPreviousEpochFinalized() public {
    epochFinalizedBlock[89157].status = "Finalized";
    //epochStatus[89157] = "Pending";
    //return epochFinalizedBlock[currentEpoch - 1].status;
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
    //Hashes memory voteHashes = epochFinalizedBlock[_epoch].winningVote;
    uint256 _blockHash = epochFinalizedBlock[_epoch].winningVote.blockHash;
    uint256 _drMerkleRoot = epochFinalizedBlock[_epoch].winningVote.merkleRoot;
    uint256 _tallyMerkleRoot = epochFinalizedBlock[_epoch].winningVote.tally;
    uint256 _previousVote = epochFinalizedBlock[_epoch].winningVote.previousVote;
    uint256 vote = getVote(
      _blockHash, _epoch, _drMerkleRoot, _tallyMerkleRoot, _previousVote);
    uint256 blockHash = voteHashes[vote].blockHash;
    return blockHash;
  }

  function getCandidates() public view returns (uint256) {
    uint256 candidate = candidates[0];
    return candidate;
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

  /*function getWinnerProposal() public returns (uint256) {
    emit Winner(epochCandidates[currentEpoch].winner);
    return epochCandidates[currentEpoch].winner;
  }*/
}