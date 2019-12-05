pragma solidity ^0.5.0;

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

  constructor (uint256 _witnetGenesis) NewBlockRelay(_witnetGenesis) public {}


  function setTimestamp(uint256 _timestamp) public returns (uint256) {
    timestamp = _timestamp;
  }

  function getTimestamp() public view returns (uint256) {
    return timestamp;
  }



}