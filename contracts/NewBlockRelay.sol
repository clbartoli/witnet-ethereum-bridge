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
  uint256 winnerVote;
  uint256 winnerId = 0;
  uint256 winnerDrMerkleRoot = 0;
  uint256 winnerTallyMerkleRoot = 0;
  uint256 winnerEpoch = 0;

  // The start of witnet to calculate after the current epoch
  uint256 witnetGenesis;
  uint256 witnetEpoch;

  uint256 endTime;
  // Inicialize the current epoch
  uint256 currentEpoch=0;
  uint256 lastVote;

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
  event Epoch(uint256 _epoch);
  event NumberVotes(uint256 _num);

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
  // Ensures the epoch is valid
  modifier onlyAfterDate(){
    require(currentEpoch > witnetEpoch, "Not valid epoch");
    _;
  }
  

  /// @dev Post new block into the block relay
  /// @param _blockHash Hash of the block header
  /// @param _drMerkleRoot Merkle root belonging to the data requests
  /// @param _tallyMerkleRoot Merkle root belonging to the tallies
  /// @param _epoch Epoch for which the block is proposed
  function proposeBlock(
    uint256 _blockHash,
    uint256 _drMerkleRoot,
    uint256 _tallyMerkleRoot,
    uint256 _epoch)
    public
    isOwner
    returns(bytes32)
  {
    uint256 epoch = updateEpoch();
    // Hash of the elements of the votation
    uint256 vote = uint256(sha256(abi.encodePacked(_blockHash, _drMerkleRoot,_tallyMerkleRoot, _epoch)));
    // add the block propose in candidates
    if (numberOfVotes[vote] == 0) {
      candidates.push(vote);
    }
    emit Epoch(epoch);
    emit Epoch(currentEpoch);
    numberOfVotes[vote] += 1;
    emit NumberVotes(numberOfVotes[vote]);
    if (vote != winnerVote) {
      if (numberOfVotes[vote] == numberOfVotes[winnerVote]) {
        emit Tie("there is been a tie");
        lastVote = vote;
      }
      if (numberOfVotes[vote] > numberOfVotes[winnerVote]) {
        winnerVote = vote;
        winnerId = _blockHash;
        winnerDrMerkleRoot = _drMerkleRoot;
        winnerTallyMerkleRoot = _tallyMerkleRoot;
        winnerEpoch = _epoch;
    }
    }

    witnetEpoch = epoch;
    endTime = witnetEpoch + 1 days;
    emit Epoch(endTime);
    return bytes32(vote);
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
  function finalResult() public onlyAfterDate() returns(uint256) {
    if (lastVote != winnerVote) {
      if (numberOfVotes[lastVote] == numberOfVotes[winnerVote]) {
        revert("There is been a tie");
    }
    }
    emit Epoch(currentEpoch);
    emit Epoch(witnetEpoch);
    postNewBlock(
      winnerId,
      winnerEpoch,
      winnerDrMerkleRoot,
      winnerTallyMerkleRoot);
    currentEpoch = witnetEpoch;
    winnerId = 0;
    winnerVote = 0;
    winnerId = 0;
    winnerDrMerkleRoot = 0;
    winnerTallyMerkleRoot = 0;
  }

  /// @dev Post new block into the block relay
  function updateEpoch() internal returns(uint256) {
    currentEpoch = (block.timestamp - witnetGenesis)/90;
    return currentEpoch;
  }
}
