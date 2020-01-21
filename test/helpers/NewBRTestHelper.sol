pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "../../contracts/NewBlockRelay.sol";
import "../../contracts/ActiveBridgeSetLib.sol";

/**
 * @title Test Helper for the new block Relay contract
 * @dev The aim of this contract is to raise the visibility modifier of new block relay contract functions for testing purposes
 * @author Witnet Foundation
 */


contract NewBRTestHelper is NewBlockRelay {
  NewBlockRelay br;
  uint256 timestamp;
  uint256 witnetGenesis;
  uint256 firstBlock;
  mapping (address => bool) public absAddresses;

  using ActiveBridgeSetLib for ActiveBridgeSetLib.ActiveBridgeSet;

   //  Ensures that the address is in the abs
  modifier isAbsMember(address _address){
    require(absAddresses[_address] == true, "Not a member of the abs");
    _;
  }

  constructor (uint256 _witnetGenesis, uint256 _epochSeconds, uint256 _firstBlock)
  NewBlockRelay(_witnetGenesis, _epochSeconds, _firstBlock) public {}

  // Pushes the activity in the ABS
  function pushActivity(address _address) public {
    absAddresses[_address] = true;
  }

  //  the ABS
  function deleteActivity(address _address) public {
    absAddresses[_address] = false;
  }

  // Updates the currentEpoch
  function updateEpoch() public view returns (uint256) {
    return currentEpoch;
  }

  // Sets the current epoch to be the next
  function nextEpoch() public {
    currentEpoch = currentEpoch + 1;
  }

  // Sets the currentEpoch
  function setEpoch(uint256 _epoch) public returns (uint256) {
    currentEpoch = _epoch;
  }

  // Gets the vote with the poposeBlock inputs
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

  // Gets the blockHash of a vote finalized in a specific epoch
  function getBlockHash(uint256 _epoch) public  returns (uint256) {
    uint256 blockHash = epochFinalizedBlock[_epoch];
    return blockHash;
  }

  // Gets the length of the candidates array
  function getCandidatesLength() public view returns (uint256) {
    return candidates.length;
  }

  // Checks if the epoch is finalized
  function checkEpochFinalized(uint256 _epoch) public returns (bool) {
    if (epochFinalizedBlock[_epoch] != 0) {
      return true;
    }
  }

}