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

  function finalresult() public returns (uint256) {
    finalResult();
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