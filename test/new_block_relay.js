const NewBlockRelay = artifacts.require("NewBlockRelay")
const sha = require("js-sha256")
const NewBRTestHelper = artifacts.require("NewBRTestHelper")
const truffleAssert = require("truffle-assertions")
/*const timeTravel = function (time) {
  return new Promise((resolve, reject) => {
    web3.currentProvider.sendAsync({
      jsonrpc: "2.0",
      method: "evm_increaseTime",
      params: [time], // 86400 is num seconds in day
      id: new Date().getTime()
    }, (err, result) => {
      if(err){ return reject(err) }
      return resolve(result)
    });
  })
}*/

contract("New Block Relay", accounts => {
    describe("New block relay test suite", () => {
    let newblockRelayInstance
      beforeEach(async () => {
        newblockRelayInstance = await NewBlockRelay.new(1568559600,{
          from: accounts[0],
        })
        contest = await NewBRTestHelper.new(1568559600)
      })
      it("should propose and post a new block", async () =>{

        // the blockhash we want to propose
        let vote = "0x" + sha.sha256("the vote to propose")
        drMerkleRoot = 1
        tallyMerkleRoot = 1
        epoch = 1
        //await timeTravel(86400 * 3) //3 days later
        //await contest.upDateEpoch()
        //await contest.nextepoch();
        //await timeTravel(86400 * 3) //3 days later


       // Propose the vote to the Block Relay
        let tx = contest.proposeBlock(vote, drMerkleRoot, tallyMerkleRoot, epoch)
        await waitForHash(tx)
        // Let's wait unitl the next epoch so we can get the final result
        await contest.nextEpoch()
        // Call the Final Result 
        await contest.finalResult()

        // Concatenation of the blockhash and the epoch=1 to check later if it's equal to the last beacon.blockHash
        let concatenated = web3.utils.hexToBytes(vote).concat(
        web3.utils.hexToBytes(
         web3.utils.padLeft(
           web3.utils.toHex(epoch), 64
             )
           )
         )
          
        
        // Should be equal the last beacon to vote
        let beacon = await contest.getLastBeacon.call()

        assert.equal(beacon, web3.utils.bytesToHex(concatenated))
      })

      it("should propose 3 blocks and post the winner", async () =>{

        // The are to votes, vote1, voted once and vote 2 voted twice.
        // It should win vote2 and so be posted in the Block Relay
        let vote1 = "0x" + sha.sha256("first vote")
        let vote2 = "0x" + sha.sha256("second vote")
        drMerkleRoot = 1
        tallyMerkleRoot = 1
        epoch = 1

        // Propose vote1 to the Block Relay
        let tx1 = contest.proposeBlock(vote1, drMerkleRoot, tallyMerkleRoot, epoch)
        await waitForHash(tx1)
        // Propose vote2 to the Block Relay
        let tx2 = contest.proposeBlock(vote2, drMerkleRoot, tallyMerkleRoot, epoch)
        // Propose for the second time vote2
        let tx3 = contest.proposeBlock(vote2, drMerkleRoot, tallyMerkleRoot, epoch)

         // Let's wait unitl the next epoch so we can get the final result
         await contest.nextEpoch()

        // Now call the final result function to select the winner
        await contest.finalResult()

        // Concatenation of the blockhash and the epoch to check later if it's equal to the last beacon
        let concatenated = web3.utils.hexToBytes(vote2).concat(
        web3.utils.hexToBytes(
          web3.utils.padLeft(
            web3.utils.toHex(epoch), 64
             )  
           )
         )

        // Should be equal the last beacon to vote2, since is the most voted
        let beacon = await contest.getLastBeacon.call()
        assert.equal(beacon, web3.utils.bytesToHex(concatenated))
      })

      it("should detect there is been a tie and revert the post", async () =>{
       // There are two blocks proposed once
       let block1 = "0x" + sha.sha256("fir vote")
       let block2 = "0x" + sha.sha256("sec vote")
       drMerkleRoot = 1
       drMerkleRoot2 = 2
       tallyMerkleRoot = 1
       epoch = 1
       
       // Propose block1 to the Block Relay
       let tx1 = contest.proposeBlock(block1, drMerkleRoot, tallyMerkleRoot, epoch)
       await waitForHash(tx1)
       // Propose block2 to the Block Relay
       let tx2 = contest.proposeBlock(block2, drMerkleRoot2, tallyMerkleRoot, epoch)
       await waitForHash(tx2)

       // Let's wait unitl the next epoch so we can get the final result
       await contest.nextEpoch() 

       // It reverts the finalResult() since it detects there is been a tie
       await truffleAssert.reverts(contest.finalResult(), "There is been a tie")
      })

      it("should revert the final result because not in a valid epoch", async () =>{
       let voteOne = "0x" + sha.sha256("propose")
       drMerkleRoot = 1
       tallyMerkleRoot = 1
       epoch = 1
       // Propose the vote to the Block Relay
       let tx = contest.proposeBlock(voteOne, drMerkleRoot, tallyMerkleRoot, epoch)
       await waitForHash(tx)

       // If we call the finaResult function it should revert since for this epoch the votation epoch is not finished
       await truffleAssert.reverts(contest.finalResult(), "Not valid epoch")
      })

      it("should set the winner to 0 after calling the final result", async () =>{

        // the blockhash we want to propose
        let vote = "0x" + sha.sha256("the vote to propose")
        drMerkleRoot = 1
        tallyMerkleRoot = 1
        epoch = 1
        //await timeTravel(86400 * 3) //3 days later
        //await contest.upDateEpoch()
        //await contest.nextepoch();
        //await timeTravel(86400 * 3) //3 days later


       // Propose the vote to the Block Relay
        let tx = contest.proposeBlock(vote, drMerkleRoot, tallyMerkleRoot, epoch)
        await waitForHash(tx)
        // Let's wait unitl the next epoch so we can get the final result
        await contest.nextEpoch()
        // Call the Final Result 
        await contest.finalResult()
        // Wait another epoch
        await contest.nextEpoch()
        // call again the final result  
        await contest.finalResult()

        // Concatenation of the blockhash and the epoch=1 to check later if it's equal to the last beacon.blockHash
        let concatenated = web3.utils.hexToBytes("0x0").concat(
        web3.utils.hexToBytes(
         web3.utils.padLeft(
           web3.utils.toHex(1), 126
             )
           )
         )
          
        
        // Should be equal the last beacon to vote
        let beacon = await contest.getLastBeacon.call()

        assert.equal(beacon, web3.utils.bytesToHex(concatenated))
      })

      /*it("should confirm the vote is a candidate", async () =>{
       let voteOne = "0x" + sha.sha256("second id")
       //let voteTwo = "0x" + sha.sha256("second id")
      //console.log(voteTwo)
      let epoch = 0
      let drRoot = 1
      let merkleRoot = 0 
      let tx1 = contest.proposeBlock(voteOne, drRoot, merkleRoot)
      //console.log(tx1)  
      await waitForHash(tx1)
      let concatenated = web3.utils.hexToBytes(voteOne).concat(
      web3.utils.hexToBytes(
        web3.utils.padLeft(
          web3.utils.toHex(drRoot), web3.utils.toHex(merkleRoot), epoch, 128
          )
        )
      )
  //console.log(web3.utils.bytesToHex(concatenated))
  //await newblockRelayInstance.finalResult()
      //let candidate = await contest.getCandidate(voteOne, drRoot, merkleRoot)
       let confirmation = await contest.confirmCandidate(web3.utils.hexToBytes(concatenated))
  //console.log(candidate)
     assert.equal(true, confirmation.success)
    })*/


})
})

const waitForHash = txQ =>
  new Promise((resolve, reject) =>
    txQ.on("transactionHash", resolve).catch(reject)
  )
