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

  // Initializes the maximum block voted
  uint256 winnerVote;
  uint256 winnerId = 0;
  uint256 winnerDrMerkleRoot = 0;
  uint256 winnerTallyMerkleRoot = 0;
  uint256 winnerEpoch = 0;

  // Needed for the constructor
  uint256 witnetGenesis;
  uint256 epochSeconds;
  // initializes the current epoch and the epoch in which is valid to propose blocks
  uint256 currentEpoch;
  uint256 proposalEpoch;
  // Initializes counting the tie votes
  uint256 tiedVote;


  // maps the candidate with the number of votes recieved
  mapping(uint256 => uint256) public numberOfVotes;

  // Last block reported
  Beacon public lastBlock;

 // map the hash of the block with the merkle roots
  mapping (uint256 => MerkleRoots) public blocks;

 // Emit an event when there is been a tie in the votation process
  event Tie(string _tie);
  // Event emitted when a new block is posted to the contract
  event NewBlock(uint256 _blockhash);

  constructor(uint256 _witnetGenesis, uint256 _epochSeconds) public{
    // Set the first epoch in Witnet plus the epoch duration when deploying the contract
    witnetGenesis = _witnetGenesis;
    epochSeconds = _epochSeconds;
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

  // Esures there is not been a tie
  modifier noTie(){
    if (tiedVote != winnerVote) {
      require(numberOfVotes[tiedVote] < numberOfVotes[winnerVote], "There has been a tie");
    }
    _;
  }

// Ensures the epoch for which the block is been proposed is valid,
// this means is one epoch before the current epoch
  modifier validEpoch(uint256 _epoch){
    currentEpoch = updateEpoch();
    if (proposalEpoch == 0) {
      proposalEpoch = currentEpoch;
    }
    require(currentEpoch - 1 == _epoch, "Proposing a block for a non valid epoch");
    _;
  }

  /// @dev Updates the epoch
  function updateEpoch() public view returns(uint256) {
    return (block.timestamp - witnetGenesis)/epochSeconds;
  }

  /// @dev Proposes a block into the block relay
  /// @param _blockHash Hash of the block header
  /// @param _epoch Epoch for which the block is proposed
  /// @param _drMerkleRoot Merkle root belonging to the data requests
  /// @param _tallyMerkleRoot Merkle root belonging to the tallies
  function proposeBlock(
    uint256 _blockHash,
    uint256 _epoch,
    uint256 _drMerkleRoot,
    uint256 _tallyMerkleRoot)
    public
    validEpoch(_epoch)
    returns(bytes32)
  {
    // Post new block after counting the votes if the proposal epoch is new
    if (currentEpoch > proposalEpoch) {
      postNewBlock(
        winnerId,
        winnerEpoch,
        winnerDrMerkleRoot,
        winnerTallyMerkleRoot);
      // Update the proposal epoch
      proposalEpoch = currentEpoch;
    }
    // Hash of the elements of the votation
    uint256 vote = uint256(
      sha256(
        abi.encodePacked(
      _blockHash,
      _epoch,
      _drMerkleRoot,
      _tallyMerkleRoot)));
    // add the block proposed to candidates
    if (numberOfVotes[vote] == 0) {
      candidates.push(vote);
    }
    // Sum one vote
    numberOfVotes[vote] += 1;
    // check if there is a tie
    if (vote != winnerVote) {
      if (numberOfVotes[vote] == numberOfVotes[winnerVote]) {
        emit Tie("there is been a tie");
        tiedVote = vote;
      }
      // Set as new winner if it has more votes
      if (numberOfVotes[vote] > numberOfVotes[winnerVote]) {
        winnerVote = vote;
        winnerId = _blockHash;
        winnerEpoch = _epoch;
        winnerDrMerkleRoot = _drMerkleRoot;
        winnerTallyMerkleRoot = _tallyMerkleRoot;
    }
    }

    return bytes32(vote);
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
  function getLastBlockHash()
    public
    view
  returns(bytes memory)
  {
    //return abi.encodePacked(lastBlock.blockHash, lastBlock.epoch);
    return abi.encodePacked(lastBlock.blockHash,uint256(1));
  }

  /// @dev Read the beacon of the last block inserted
  /// @return bytes to be signed by bridge nodes
  function getLastBeacon()
    public
    view
  returns(bytes memory)
  {
    //return abi.encodePacked(lastBlock.blockHash, lastBlock.epoch);
    return abi.encodePacked(lastBlock.blockHash, lastBlock.epoch);
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
    internal
    noTie()
    blockDoesNotExist(_blockHash)
  {
    uint256 id = _blockHash;
    lastBlock.blockHash = id;
    lastBlock.epoch = _epoch;
    blocks[id].drHashMerkleRoot = _drMerkleRoot;
    blocks[id].tallyHashMerkleRoot = _tallyMerkleRoot;
    emit NewBlock(id);
    // Set the winner values equal 0
    winnerId = 0;
    winnerVote = 0;
    winnerId = 0;
    winnerEpoch = 0;
    winnerDrMerkleRoot = 0;
    winnerTallyMerkleRoot = 0;
    // Delete the condidates array so its empty for next epoch
    for (uint i = 0; i <= candidates.length - 1; i++) {
      delete candidates[i];
    }
  }

}
