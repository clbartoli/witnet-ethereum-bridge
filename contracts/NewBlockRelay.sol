pragma solidity ^0.5.0;


/**
 * @title New Block relay contract
 * @notice Contract to store/read block headers from the Witnet network
 * @author Witnet Foundation
 */
contract NewBlockRelay {

  struct MerkleRoots {
    // hash of the merkle root of the DRs in Witnet
    uint256 drHashMerkleRoot;
    // hash of the merkle root of the tallies in Witnet
    uint256 tallyHashMerkleRoot;
  }
  struct Beacon {
    // hash of the last block
    uint256 blockHash;
    // epoch of the last block
    uint256 epoch;
  }

  // Array with the votes for the possible block
  uint256[] public candidates;

  // Inicialize the maximum block voted
  uint256 winnerVote = 0;
  uint256 winnerId = 0;
  uint256 winnerDrMerkleRoot = 0;
  uint256 winnerTallyMerkleRoot = 0;

  // The start of witnet to calculate after the current epoch
  uint256 witnetGenesis;

  // Inicialize the current epoch
  uint256 currentEpoch;

  // maps the candidate with the number of votes recieved
  mapping(uint256 => uint256) public numberOfVotes;

  // Address of the block pusher
  address witnet;
  // Last block reported
  Beacon public lastBlock;

 // map the hash of the block with the merkle roots
  mapping (uint256 => MerkleRoots) public blocks;

  // Event emitted when a new block is posted to the contract
  event NewBlock(address indexed _from, uint256 _id);
  event Winner(uint256 _winner);
  event Tie(string _tie);

  constructor(uint256 _witnetGenesis) public{
    // Only the contract deployer is able to push blocks
    witnet = msg.sender;
    witnetGenesis = _witnetGenesis;
  }

  // Only the owner should be able to push blocks
  modifier isOwner() {
    require(msg.sender == witnet, "Sender not authorized"); // If it is incorrect here, it reverts.
    _; // Otherwise, it continues.
  }
  // Ensures block exists
  modifier blockExists(uint256 _id){
    require(blocks[_id].drHashMerkleRoot!=0, "Non-existing block");
    _;
  }
   // Ensures block does not exist
  modifier blockDoesNotExist(uint256 _id){
    require(blocks[_id].drHashMerkleRoot==0, "The block already existed");
    _;
  }


  /// @dev Post new block into the block relay
  /// @param _blockHash Hash of the block header
  /// @param _drMerkleRoot Merkle root belonging to the data requests
  /// @param _tallyMerkleRoot Merkle root belonging to the tallies
  function proposeBlock(
    uint256 _blockHash,
    //uint256 _epoch,
    uint256 _drMerkleRoot,
    uint256 _tallyMerkleRoot)
    public
    isOwner
    blockDoesNotExist(_blockHash)
    returns(bytes32)
  {
    // Hash of the elements of the votation
    uint256 vote = uint256(sha256(abi.encodePacked(_blockHash, _drMerkleRoot,_tallyMerkleRoot)));
    // add the block propose in candidates
    if (numberOfVotes[vote] == 0) {
      candidates.push(vote);
    }
    numberOfVotes[vote] += 1;
    if (numberOfVotes[vote] == numberOfVotes[winnerVote]) {
      emit Tie("there is been a tie");
    }
    if (numberOfVotes[vote] > numberOfVotes[winnerVote]) {
      winnerVote = vote;
      winnerId = _blockHash;
      winnerDrMerkleRoot = _drMerkleRoot;
      winnerTallyMerkleRoot = _tallyMerkleRoot;
    }
    finalResult();
    //lastBlock.blockHash = winnerId;
    //lastBlock.epoch = 0;
    //postNewBlock(
     // winnerId, currentEpoch, winnerDrMerkleRoot, winnerTallyMerkleRoot);
    emit Winner(winnerId);
    return bytes32(winnerId);
  }

  /// @dev Post new block into the block relay
  /// @param _blockHash Hash of the block header
  /// @param _epoch Witnet epoch to which the block belongs to
  /// @param _drMerkleRoot Merkle root belonging to the data requests
  /// @param _tallyMerkleRoot Merkle root belonging to the tallies
  function postNewBlock(
    uint256 _blockHash,
    uint256 _epoch,
    uint256 _drMerkleRoot,
    uint256 _tallyMerkleRoot)
    public
    isOwner
    blockDoesNotExist(_blockHash)
  {
    uint256 id = _blockHash;
    lastBlock.blockHash = id;
    lastBlock.epoch = _epoch;
    blocks[id].drHashMerkleRoot = _drMerkleRoot;
    blocks[id].tallyHashMerkleRoot = _tallyMerkleRoot;
  }

  /// @dev Retrieve the requests-only merkle root hash that was reported for a specific block header.
  /// @param _blockHash Hash of the block header
  /// @return Requests-only merkle root hash in the block header.
  function readDrMerkleRoot(uint256 _blockHash)
    public
    view
    blockExists(_blockHash)
  returns(uint256 drMerkleRoot)
    {
    drMerkleRoot = blocks[_blockHash].drHashMerkleRoot;
  }

  /// @dev Retrieve the tallies-only merkle root hash that was reported for a specific block header.
  /// @param _blockHash Hash of the block header
  /// tallies-only merkle root hash in the block header.
  function readTallyMerkleRoot(uint256 _blockHash)
    public
    view
    blockExists(_blockHash)
  returns(uint256 tallyMerkleRoot)
  {
    tallyMerkleRoot = blocks[_blockHash].tallyHashMerkleRoot;
  }

  /// @dev Read the beacon of the last block inserted
  /// @return bytes to be signed by bridge nodes
  function getLastBeacon()
    public
    view
  returns(bytes memory)
  {
    return abi.encodePacked(lastBlock.blockHash, lastBlock.epoch);
  }

  /// @dev Post new block into the block relay
  function finalResult() internal returns(uint256) {
    uint256 witnetEpoch = upDateEpoch();
    if (currentEpoch != witnetEpoch) {
      postNewBlock(
        winnerId,
        currentEpoch,
        winnerDrMerkleRoot,
        winnerTallyMerkleRoot);
      currentEpoch = witnetEpoch;
      return winnerId;
    }
  }

  /// @dev Post new block into the block relay
  function upDateEpoch() internal view returns(uint256) {
    uint256 witnetEpoch = (block.timestamp - witnetGenesis)/90;
    return witnetEpoch;
  }
}
