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

  constructor (uint256 _witnetGenesis) NewBlockRelay(_witnetGenesis) public {}

 /* function winner() public view returns (uint256) {

  }*/


  function upDateEpoch() public returns (uint256) {
    uint256 currentEpoch = updateEpoch();
    return currentEpoch;
  }

  // Sets the current epoch to be the next
  function nextEpoch() public {
    currentEpoch = currentEpoch + 1;
    emit Epoch(currentEpoch);
    emit Epoch(witnetEpoch);
  }

  function setTimestamp(uint256 _timestamp) public returns (uint256) {
    timestamp = _timestamp;
  }

  function getTimestamp() public view returns (uint256) {
    return timestamp;
  }

  function confirmCandidate(uint256 _candidate) public view returns (bool) {
    //bytes memory candidate = abi.encodePacked(_candidate,uint256(1));
    if (numberOfVotes[_candidate] != 0) {
      return true;
    } else {
      return false;
    }
  }


}