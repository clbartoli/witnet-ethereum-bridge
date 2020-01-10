pragma solidity ^0.5.0;

import "./ActiveBridgeSetLib.sol";
import "./WitnetBridgeInterface.sol";


/**
 * @title New Block relay contract
 * @notice Contract to store/read block headers from the Witnet network
 * @author Witnet Foundation
 */
contract NewBlockRelay is WitnetBridgeInterface(address(this), 2) {

  using ActiveBridgeSetLib for ActiveBridgeSetLib.ActiveBridgeSet;

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

  // Struct with the hashes of a votation
  struct Hashes {
    uint256 blockHash;
    uint256 merkleRoot;
    uint256 tally;
    uint256 previousVote;
  }

  struct FinalizedBlock {
    Hashes winningVote;
    string status;
  }


  // Array with the votes for the possible block
  uint256[] public candidates;



  // Initializes the block with the maximum number of votes
  uint256 winnerVote;
  uint256 winnerId = 0;
  uint256 winnerDrMerkleRoot = 0;
  uint256 winnerTallyMerkleRoot = 0;
  uint256 winnerEpoch = 0;

  // Needed for the constructor
  uint256 witnetGenesis;
  uint256 epochSeconds;
  uint256 firstBlock;

  // Initializes the current epoch and the epoch in which it is valid to propose blocks
  uint256 currentEpoch;
  uint256 proposalEpoch;

  // Initializes the tied vote count
  uint256 tiedVote;

  uint256 activeIdentities = uint256(abs.activeIdentities);

  // Last block reported
  Beacon public lastBlock;



  // Map a block proposed with the number of votes recieved
  mapping(uint256 => uint256) public numberOfVotes;

 // Map the hash of the block with the merkle roots
  mapping (uint256 => MerkleRoots) public blocks;

  // Map a vote with its drMerkleRoot and Tally

  mapping(uint256 => Hashes) internal voteHashes;

  mapping(uint256 => FinalizedBlock) internal epochFinalizedBlock;

  mapping(uint256 => Hashes) internal finalVoteHashes;


 // Event emitted when there's been a tie in the votation process
  event Tie(string _tie);

  constructor(uint256 _witnetGenesis, uint256 _epochSeconds, uint256 _firstBlock) public{
    // Set the first epoch in Witnet plus the epoch duration when deploying the contract
    witnetGenesis = _witnetGenesis;
    epochSeconds = _epochSeconds;
    firstBlock = _firstBlock;
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

   //  Ensures that neither Poi nor PoE are allowed if the epoch is pending
  modifier finalizedEpoch(uint256 _epoch){
    require(
      keccak256(abi.encodePacked((epochFinalizedBlock[_epoch].status))) ==
      keccak256(abi.encodePacked(("Finalized"))),
      "The block has not been finalized");
    _;
  }

   //  Ensures that the msg.sender is in the abs
  modifier absMembership(address _address){
    require(abs.absMembership(_address) == true, "Not a member of the abs");
    _;
  }


  modifier noTie(){
    if (tiedVote != winnerVote) {
      require(numberOfVotes[tiedVote] < numberOfVotes[winnerVote], "There has been a tie");
    }
    _;
  }

// Ensures the epoch for which the block is been proposed is valid
// Valid if it is one epoch before the current epoch
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
    uint256 _tallyMerkleRoot,
    uint256 _previousVote
    )
    public
    validEpoch(_epoch)
    absMembership(msg.sender)
    returns(bytes32)
  {
    // Post new block if the proposal epoch has changed
    if (currentEpoch > proposalEpoch) {

      postNewBlock(
        winnerVote,
        winnerId,
        winnerEpoch,
        winnerDrMerkleRoot,
        winnerTallyMerkleRoot,
        voteHashes[winnerVote].previousVote);
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
      _tallyMerkleRoot,
      _previousVote)));
    if (numberOfVotes[vote] == 0) {
      // Add the vote to candidates
      candidates.push(vote);
      // Mapping the vote into its hashes
      voteHashes[vote].blockHash = _blockHash;
      voteHashes[vote].merkleRoot = _drMerkleRoot;
      voteHashes[vote].tally = _tallyMerkleRoot;
      voteHashes[vote].previousVote = _previousVote;
    }

    // Sum one vote
    numberOfVotes[vote] += 1;
    // Check if there is a tie
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
  function getLastBeacon()
    public
    view
  returns(bytes memory)
  {
    return abi.encodePacked(lastBlock.blockHash, lastBlock.epoch);
  }

/// @dev Verifies the validity of a PoI against the DR merkle root
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..]
  /// @param _blockHash the blockHash
  /// @param _index the index in the merkle tree of the element to verify
  /// @param _element the leaf to be verified
  /// @return true or false depending the validity
  function verifyDrPoi(
    uint256[] memory _poi,
    uint256 _blockHash,
    uint256 _index,
    uint256 _element)
  public
  view
  blockExists(_blockHash)
  finalizedEpoch(currentEpoch)
  returns(bool)
  {
    uint256 drMerkleRoot = blocks[_blockHash].drHashMerkleRoot;
    return(verifyPoi(
      _poi,
      drMerkleRoot,
      _index,
      _element));
  }

  /// @dev Verifies the validity of a PoI against the tally merkle root
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..]
  /// @param _blockHash the blockHash
  /// @param _index the index in the merkle tree of the element to verify
  /// @param _element the element
  /// @return true or false depending the validity
  function verifyTallyPoi(
    uint256[] memory _poi,
    uint256 _blockHash,
    uint256 _index,
    uint256 _element)
  public
  view
  blockExists(_blockHash)
  returns(bool)
  {
    uint256 tallyMerkleRoot = blocks[_blockHash].tallyHashMerkleRoot;
    return(verifyPoi(
      _poi,
      tallyMerkleRoot,
      _index,
      _element));

  }

  /// @dev Post new block into the block relay
  /// @param _blockHash Hash of the block headerPost
  /// @param _epoch Witnet epoch to which the block belongs to
  /// @param _drMerkleRoot Merkle root belonging to the data requests
  /// @param _tallyMerkleRoot Merkle root belonging to the tallies
  function postNewBlock(
    uint256 _vote,
    uint256 _blockHash,
    uint256 _epoch,
    uint256 _drMerkleRoot,
    uint256 _tallyMerkleRoot,
    uint256 _previousVote)
    private
    blockDoesNotExist(_blockHash)
  {
    if (3*numberOfVotes[winnerVote] < 2*activeIdentities) {
      epochFinalizedBlock[_epoch].status = "Pending";
      // Set the winner values to 0
      winnerVote = 0;
      winnerId = 0;
      winnerEpoch = 0;
      winnerDrMerkleRoot = 0;
      winnerTallyMerkleRoot = 0;
    } else {
      // Map the epoch to the _vote's Hashes
      epochFinalizedBlock[_epoch].winningVote = voteHashes[_vote];
      epochFinalizedBlock[_epoch].status = "Finalized";
      finalVoteHashes[_vote] = epochFinalizedBlock[_epoch].winningVote;
      blocks[_blockHash].drHashMerkleRoot = _drMerkleRoot;
      blocks[_blockHash].tallyHashMerkleRoot = _tallyMerkleRoot;
      // Check if the status of the previous block is Pending and so it needs to be finalized
      if (keccak256(abi.encodePacked((epochFinalizedBlock[_epoch-1].status))) == keccak256(abi.encodePacked(("Pending")))) {
        uint x;
        // Select the last Finalized epoch
        for (uint i; i>=0; i++) {
          if (keccak256(abi.encodePacked(epochFinalizedBlock[_epoch-i-1].status)) != keccak256(abi.encodePacked(("Finalized")))) {
            x = i;
            uint256 previousFinalVote;
            // Finalize the previous epochs with the corresponding previous votes and hashes
            previousFinalVote = epochFinalizedBlock[_epoch-i].winningVote.previousVote;
            epochFinalizedBlock[_epoch - i-1].winningVote = voteHashes[previousFinalVote];
            finalVoteHashes[previousFinalVote] = epochFinalizedBlock[_epoch - i-1].winningVote;
            uint256 previousBlockHash = finalVoteHashes[previousFinalVote].blockHash;
            blocks[previousBlockHash].drHashMerkleRoot = finalVoteHashes[previousFinalVote].merkleRoot;
            blocks[previousBlockHash].tallyHashMerkleRoot = finalVoteHashes[previousFinalVote].tally;
            // Set the previous status to Finalized
            epochFinalizedBlock[_epoch-i-1].status = "Finalized";
          } else if (keccak256(abi.encodePacked((epochFinalizedBlock[_epoch-i-1].status))) == keccak256(abi.encodePacked(("Finalized")))) {
            break;
          }
        }
        // Post each block as last beacon, from the oldest to the newest
        for (uint j; j <= x-1; j++) {
          lastBlock.blockHash = epochFinalizedBlock[_epoch - x + j].winningVote.blockHash;
          lastBlock.epoch = _epoch - x + j;
        }
       }
       // Post the last block
      lastBlock.blockHash = _blockHash;
      lastBlock.epoch = _epoch;

    // Set the winner values equal 0
      winnerId = 0;
      winnerVote = 0;
      winnerId = 0;
      winnerEpoch = 0;
      winnerDrMerkleRoot = 0;
      winnerTallyMerkleRoot = 0;
      // Delete the condidates array so its empty for next epoch
      for (uint i = 0; i <= candidates.length - 1; i++) {
        delete voteHashes[candidates[i]];}
      delete candidates;

  }
  }

  /// @dev Verifies the validity of a PoI
  /// @param _poi the proof of inclusion as [sibling1, sibling2,..]
  /// @param _root the merkle root
  /// @param _index the index in the merkle tree of the element to verify
  /// @param _element the leaf to be verified
  /// @return true or false depending the validity
  function verifyPoi(
    uint256[] memory _poi,
    uint256 _root,
    uint256 _index,
    uint256 _element)
  private pure returns(bool)
  {
    uint256 tree = _element;
    uint256 index = _index;
    // We want to prove that the hash of the _poi and the _element is equal to _root
    // For knowing if concatenate to the left or the right we check the parity of the the index
    for (uint i = 0; i<_poi.length; i++) {
      if (index%2 == 0) {
        tree = uint256(sha256(abi.encodePacked(tree, _poi[i])));
      } else {
        tree = uint256(sha256(abi.encodePacked(_poi[i], tree)));
      }
      index = index>>1;
    }
    return _root==tree;
  }

}
