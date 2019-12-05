pragma solidity ^0.5.0;

interface interfaceBlockRelay {

    function proposeNeBlock() external;
    function readDrMerkleRoot() external;
    function readTallyMerkleRoot() external;
    function getLastBeacon() external;
    function finalResult() external;
    function upDateEpoch() external;
}