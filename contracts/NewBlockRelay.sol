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
  // ActiveBridgeSetLib absLib = new ActiveBridgeSetLib;
  // WitnetBridgeInterface wbi = new WitnetBridgeInterface(address(this), 2);

  struct MerkleRoots {
    // hash of the merkle root of the DRs in Witnet
    uint256 drHashMerkleRoot;
    // hash of the merkle root of the tallies in Witnet
    uint256 tallyHashMerkleRoot;
    // hash of the previous block
    uint256 previousBlockHash;
  }
  struct Beacon {
    // hash of the last block
    uint256 blockHash;
    // epoch of the last block
    uint256 epoch;
  }

  //address[] abs = getABS(currentEpoch);
  
  // Struct for the candidates for final block
  struct Candidates {
    uint256[] candidate;
    uint256 winner;
    uint256 numberVotesWinner;
    uint256 winnerMR;
    uint256 winnerTally;

  }

  struct Hashes {
    uint256 blockHash;
    uint256 merkleRoot;
    uint256 tally;
    uint256 previousVote;
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

  // Initializes the current epoch and the epoch in which it is valid to propose blocks
  uint256 currentEpoch;
  uint256 proposalEpoch;

  // Initializes the tied vote count
  uint256 tiedVote;

  uint256 activeIdentities = uint256(abs.activeIdentities);

  // Last block reported
  Beacon public lastBlock;

  Candidates public winnerProposal;


  // Map a block proposed with the number of votes recieved
  mapping(uint256 => uint256) public numberOfVotes;

 // Map the hash of the block with the merkle roots
  mapping (uint256 => MerkleRoots) public blocks;

  // Map an epoch with the candidates for final block for that epoch
  mapping(uint256 => Candidates) internal epochCandidates;

  // Map a vote with its drMerkleRoot and Tally

  mapping(uint256 => Hashes) internal voteHashes;

  // Mapping an epoch with its status
  mapping(uint256 => string) internal epochStatus;

  // Mapping from an epoch to the blockHash once finalized
  mapping(uint256 => uint256) internal epochBlockHash;


 // Event emitted when there's been a tie in the votation process
  event Tie(string _tie);
  // Event emitted when a new block is posted to the contract
  event NewBlock(uint256 _blockhash);
  event Winner(uint256 _winner);

  event Abs(address[] _absIdentities);
  event AbsNumberElements(uint256 _numberElements);

  event EpochStatus(string _epochStatus);

  event NumberOfVotes(uint256 _vote);

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

   //  Ensures that neither Poi nor PoE are allowed if the epoch is pending
  modifier finalizedEpoch(uint256 _epoch){
    require(keccak256(abi.encodePacked((epochStatus[_epoch]))) == keccak256(abi.encodePacked(("Finalized"))), "The block has not been finalized");
    _;
  }

   //  Ensures that the msg.sender is in the abs
  modifier absMembership(address _address){
    require(abs.absMembership(_address) == true, "Not a member of the abs");
    _;
  }

  // Esures there is not been a tie
  /*modifier noTie(){
    if (tiedVote != winnerVote) {
      require(numberOfVotes[tiedVote] < numberOfVotes[winnerVote], "There has been a tie");
    }
    _;
  }*/

   modifier noTie(){
    if (tiedVote != winnerVote) {
      require(numberOfVotes[tiedVote] < numberOfVotes[winnerVote], "There has been a tie");
    }
    _;
  }

   // Ensures the maximum is achieved with at least 2/3 of the ABS
  modifier minNumberVotes(uint256 _blockHash, uint256 _epoch, uint256 _drMerkleRoot, uint256 _tallyMerkleRoot){
    uint256 vote = uint256(
      sha256(
        abi.encodePacked(
      _blockHash,
      _epoch,
      _drMerkleRoot,
      _tallyMerkleRoot)));
      if (3*numberOfVotes[vote] < 2*activeIdentities) {
        epochStatus[_epoch] = "Pending";
        //revert();
      }
    require(3*numberOfVotes[vote] >= 2*activeIdentities, "Not achieved the minimum number of votes");
    _;
  }

  /*modifier minNumberVotes(uint256 _blockHash, uint256 _epoch, uint256 _drMerkleRoot, uint256 _tallyMerkleRoot){
    uint256 vote = uint256(
      sha256(
        abi.encodePacked(
      _blockHash,
      _epoch,
      _drMerkleRoot,
      _tallyMerkleRoot)));
    if (3*numberOfVotes[vote] >= 2*activeIdentities) {
      
    }

    _;
  }*/


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

   // Ensures block does not exist
  /*modifier blockDoesNotExist(uint256 _id){
    require(blocks[_id].drHashMerkleRoot==0, "The block already existed");
    _;
  }*/

  /*function epochFinalized(uint256 _epoch) public returns(bool) {
    // require (_epoch < currentEpoch, "")
    if (epochCandidates[_epoch] == 0) {
      return true;
    }
  }*/

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
    address[] memory absIdentities = getABS(_epoch);
    //emit Abs(absIdentities);
    //uint256 activeIdentities = abs.activeIdentities;
    // emit AbsNumberElements(activeIdentities);
    // Post new block if the proposal epoch has changed
    if (currentEpoch > proposalEpoch) {
      postNewBlock(
        winnerId,
        winnerEpoch,
        winnerDrMerkleRoot,
        winnerTallyMerkleRoot,
        _previousVote);
      // Update the proposal epoch
      proposalEpoch = currentEpoch;
    }
    string memory _epochStatus = epochStatus[_epoch-1];
      emit EpochStatus(_epochStatus);
    // Hash of the elements of the votation
    uint256 vote = uint256(
      sha256(
        abi.encodePacked(
      _blockHash,
      _epoch,
      _drMerkleRoot,
      _tallyMerkleRoot,
      _previousVote)));
    // Add the block proposed to candidates
    if (numberOfVotes[vote] == 0) {
      candidates.push(vote);
      //Hashes memory voteHash;
      blocks[_blockHash].drHashMerkleRoot = _drMerkleRoot;
      blocks[_blockHash].tallyHashMerkleRoot = _tallyMerkleRoot;
      blocks[_blockHash].previousBlockHash = _previousVote;
      //voteHashes[vote] = voteHash;
      // Candidates memory winnerProposal;
      // winnerProposal.candidate = candidates;
      // epochCandidates[proposalEpoch] = winnerProposal;
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
    //Candidates memory winnerProposal;
    /*winnerProposal.candidate = candidates;
    winnerProposal.winner = winnerId;
    winnerProposal.numberVotesWinner = numberOfVotes[winnerVote];
    epochCandidates[proposalEpoch] = winnerProposal;*/
    }
    emit NumberOfVotes(numberOfVotes[vote]);

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
    //return abi.encodePacked(lastBlock.blockHash, lastBlock.epoch);
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
    uint256 _blockHash,
    uint256 _epoch,
    uint256 _drMerkleRoot,
    uint256 _tallyMerkleRoot,
    uint256 _previousVote)
    internal
    // noTie()
    // minNumberVotes(_blockHash, _epoch, _drMerkleRoot, _tallyMerkleRoot)
    //blockDoesNotExist(_blockHash)
  {
    uint256 vote = uint256(
      sha256(
        abi.encodePacked(
      _blockHash,
      _epoch,
      _drMerkleRoot,
      _tallyMerkleRoot,
      _previousVote)));
      string memory _epochStatus = epochStatus[_epoch-1];
      emit EpochStatus(_epochStatus);
      emit NumberOfVotes(numberOfVotes[winnerVote]);
     if (3*numberOfVotes[winnerVote] < 2*activeIdentities) {
      // emit NumberOfVotes(numberOfVotes[vote]);
        epochStatus[_epoch] = "Pending";
        // epochBlockHash[_epoch] = _blockHash;
        //revert();
        winnerId = 0;
        winnerVote = 0;
        winnerId = 0;
        winnerEpoch = 0;
        winnerDrMerkleRoot = 0;
        winnerTallyMerkleRoot = 0;
      } 
      else {
       if (keccak256(abi.encodePacked((epochStatus[_epoch-2]))) == keccak256(abi.encodePacked(("Pending")))){
       // Vote for the previous epoch
       epochBlockHash[_epoch-2] = _previousVote;
       uint x = 1;
       for (uint i; i > 1; i++) {
        if (keccak256(abi.encodePacked((epochStatus[_epoch-i]))) == keccak256(abi.encodePacked(("Finalized")))) {
          x = i;
        break;
        }
        
        }
       for (uint j; j <x; j++) {
        lastBlock.blockHash = epochBlockHash[_epoch - x + j];
        lastBlock.epoch = _epoch -x - j;
        epochStatus[_epoch - x + j] = "Finalized";
        }
      epochBlockHash[_epoch-1] = _previousVote;
      lastBlock.blockHash = _previousVote;
      lastBlock.epoch = _epoch-1;
      epochStatus[_epoch-1] = "Finalized";
      }
    uint256 id = _blockHash;
    lastBlock.blockHash = id;
    lastBlock.epoch = _epoch;
    blocks[id].drHashMerkleRoot = _drMerkleRoot;
    blocks[id].tallyHashMerkleRoot = _tallyMerkleRoot;
    epochStatus[_epoch] = "Finalized";
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
  
    epochBlockHash[_epoch] = _blockHash; 
  }
  }
  

  
  /*function recountVotes(uint256 _vote)
    internal
    // noTie()
    //minNumberVotes(_blockHash, _epoch, _drMerkleRoot, _tallyMerkleRoot)
    //blockDoesNotExist(_blockHash)
  {
    uint256 blockHash = _vote;
    uint256 merkleRoot = blocks[blockHash].drHashMerkleRoot;
    uint256 tally = blocks[blockHash].tallyHashMerkleRoot;
    uint256 previousBlockHash = blocks[blockHash].previousBlockHash;
    /*uint256 vote = uint256(
      sha256(
        abi.encodePacked(
      _blockHash,
      _epoch,
      _drMerkleRoot,
      _tallyMerkleRoot)));*/
    // numerOfVotes[vote] +=1;
    //proposeBlock(blockHash, currentEpoch - 1, merkleRoot, tally, previousBlockHash);
    /*epochCandidates[currentEpoch -1];
    uint256 winnerCandidate = epochCandidates[currentEpoch -1].winner;
    if (numberOfVotes[_vote] == 0) {
      epochCandidates[currentEpoch -1].candidate.push(_vote);
      // Candidates memory winnerProposal;
      // winnerProposal.candidate = candidates;
      // epochCandidates[proposalEpoch] = winnerProposal;
    }
    // Sum one vote
    numberOfVotes[_vote] += 1;
    // Check if there is a tie
    if (_vote != winnerCandidate) {
      if (numberOfVotes[_vote] == numberOfVotes[winnerCandidate]) {
        emit Tie("there is been a tie");
        tiedVote = _vote;
      }
      // Set as new winner if it has more votes
      if (numberOfVotes[_vote] > numberOfVotes[winnerCandidate]) {
        winnerCandidate = _vote;
        epochCandidates[currentEpoch -1].numberVotesWinner = numberOfVotes[_vote];
        if (3*numberOfVotes[_vote] >= 2*activeIdentities) {
          uint256 blockHash = voteHashes[_vote].blockHash;
          uint256 mRoot = voteHashes[_vote].merkleRoot;
          uint256 tally = voteHashes[_vote].tally;
          uint256 previousVote = voteHashes[_vote].previousVote;
          postNewBlock(blockHash, currentEpoch -1, mRoot, tally, previousVote);
        }
    //Candidates memory winnerProposal;
    /*winnerProposal.candidate = candidates;
    winnerProposal.winner = winnerId;
    winnerProposal.numberVotesWinner = numberOfVotes[winnerVote];
    epochCandidates[proposalEpoch] = winnerProposal;
    emit Winner(winnerProposal.winner);*/
  //}

  //}
//}

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
