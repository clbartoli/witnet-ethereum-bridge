pragma solidity ^0.5.0;

import "../../contracts/WitnetRequestsBoardProxy.sol";


/**
 * @title Test Helper for the WitnetRequestsBoardProxy contract
 * @dev The aim of this contract is:
 * 1. Raise the visibility modifier of WitnetRequestsBoardProxy contract functions for testing purposes
 * @author Witnet Foundation
 */
contract WrbProxyTestHelper is WitnetRequestsBoardProxy {

  constructor (address _witnetRequestsBoardAddress) WitnetRequestsBoardProxy(_witnetRequestsBoardAddress) public {}

  function updateCurrentLastId() public view returns(uint256) {
    return currentLastId;
  }

  function checkLastId(uint256 _id) public returns(bool) {
    if (_id == currentLastId) {
      return true;
    } else {
      false;
    }
  }

  function getWrbAddress() public view returns(address) {
    return witnetRequestsBoardAddress;
  }

  function getLastId() public view returns(uint256) {
    uint256 n = controllers.length;
    uint256 offset = controllers[n - 1].lastId;
    return offset;
  }

  function getControllerAddress(uint256 _id) public returns(address) {
    address wrb;
    uint256 offset;
    (wrb, offset) = getController(_id);
    return wrb;
  }

  function getLastControllerId() public returns(uint256) {
    uint256 n = controllers.length;
    uint256 lastId = controllers[n - 1].lastId;
    return lastId;
  }

  function getCurrentController() public returns(address) {
    address wrb = witnetRequestsBoardAddress;
    return wrb;
  }

//   function _witnetUpgradeDataRequest(uint256 _id, uint256 _tallyReward) public payable {
//     witnetUpgradeRequest(_id, _tallyReward);
//   }

//   function _witnetReadResult (uint256 _id) public view returns(bytes memory) {
//     return witnetReadResult(_id);
//   }
}
