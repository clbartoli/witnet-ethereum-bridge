pragma solidity ^0.5.0;

import "./WitnetRequestsBoardProxy.sol";


/**
 * @title State Contract
 * @notice Contract to act as storage of the state of the ids in the WitnetRequestBoardProxy
 * DISCLAIMER: this is a work in progress, meaning the contract could be voulnerable to attacks
 * @author Witnet Foundation
 */
contract StateContract {

  address public witnetRequestsBoardProxyAddress;
  WitnetRequestsBoardProxy wrbProxy;

  uint256[] public lastRequestsIds;
  uint256 public lastIdPosition;
  address[] lastWrb;
//   WitnetRequestsBoardInterface witnetRequestsBoardInstance;

//   uint256 lastDrId;
//   mapping(uint256 => address)  idWrb;
//   uint256[] lastIds;

//   event Controllerget(uint256, address);
  modifier onlyProxy() {
    require(msg.sender == witnetRequestsBoardProxyAddress, "This function is only callable from Proxy");
    _;
  }

  constructor(address _wrbProxyAddress) public {
    witnetRequestsBoardProxyAddress = _wrbProxyAddress;
    // witnetRequestsBoardInstance = WitnetRequestsBoardInterface(_witnetRequestsBoardAddress);
  }

  function getLastRequestsIds() public view returns(uint256[] memory) {
    return lastRequestsIds;
  }

  function getLastIdPosition() public view returns(uint256) {
    return lastIdPosition;
  }

  function getLastId() public view returns(uint256) {
    uint256 n = lastRequestsIds.length;
    return lastRequestsIds[n - 1];
  }

 
  function pushId(uint256 _id) public onlyProxy {
    lastRequestsIds.push(_id);
  }

  function clearIds() public onlyProxy {
    for (uint256 i = lastIdPosition; i < lastRequestsIds.length - 1; i++) {
      delete lastRequestsIds[i];
    }
    uint256 n = lastRequestsIds.length;
    updateLastIdPosition(n - 1);
  }

  function updateLastIdPosition(uint256 _lastIdPosition) public onlyProxy {
    lastIdPosition = _lastIdPosition;
  }




}