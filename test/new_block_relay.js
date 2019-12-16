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
    let contest
    beforeEach(async () => {
      await NewBlockRelay.new(1568559600, 90, {
        from: accounts[0],
      })
      contest = await NewBRTestHelper.new(1568559600, 90)
    })
    it("should propose and post a new block", async () => {
      // the blockhash we want to propose
      const vote = "0x" + sha.sha256("the vote to propose")
      const drMerkleRoot = 1
      const tallyMerkleRoot = 1
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      const epoch = await contest.updateEpoch.call()
      // Propose the vote to the Block Relay
      const tx = contest.proposeBlock(vote, drMerkleRoot, tallyMerkleRoot, epoch - 1)
      await waitForHash(tx)
      // Let's wait unitl the next epoch so we can get the final result
      await contest.nextEpoch()
      // Call the Final Result
      await contest.finalresult()
      // Concatenation of the blockhash and the epoch=1 to check later if it's equal to the last beacon.blockHash
      const concatenated = web3.utils.hexToBytes(vote).concat(
        web3.utils.hexToBytes(
          web3.utils.padLeft(
            web3.utils.toHex(epoch - 1), 64
          )
        )
      )
      // Should be equal the last beacon to vote
      const beacon = await contest.getLastBeacon.call()
      assert.equal(beacon, web3.utils.bytesToHex(concatenated))
    })

    it("should post a new block when proposing in next epoch", async () => {
      // the blockhash we want to propose
      const vote = "0x" + sha.sha256("the vote to propose")
      const vote2 = "0x" + sha.sha256("second vote")
      const drMerkleRoot = 1
      const tallyMerkleRoot = 1
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      const epoch = await contest.updateEpoch.call()
      // Propose the vote to the Block Relay
      const tx = contest.proposeBlock(vote, drMerkleRoot, tallyMerkleRoot, epoch - 1)
      await waitForHash(tx)
      // Let's wait unitl the next epoch so we can get the final result
      await contest.nextEpoch()
      // Call the Final Result
      // await contest.finalResult()
      contest.proposeBlock(vote2, drMerkleRoot, tallyMerkleRoot, epoch)
      // Concatenation of the blockhash and the epoch=1 to check later if it's equal to the last beacon
      const concatenated = web3.utils.hexToBytes(vote).concat(
        web3.utils.hexToBytes(
          web3.utils.padLeft(
            web3.utils.toHex(epoch - 1), 64
          )
        )
      )
      // Should be equal the last beacon to vote
      const beacon = await contest.getLastBeacon.call()
      assert.equal(beacon, web3.utils.bytesToHex(concatenated))
    })

    it("should propose 3 blocks and post the winner", async () => {
      // The are to votes, vote1, voted once and vote 2 voted twice.
      // It should win vote2 and so be posted in the Block Relay
      const vote1 = "0x" + sha.sha256("first vote")
      const vote2 = "0x" + sha.sha256("second vote")
      const drMerkleRoot = 1
      const tallyMerkleRoot = 1
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      const epoch = await contest.updateEpoch.call()
      // Propose vote1 to the Block Relay
      const tx1 = contest.proposeBlock(vote1, drMerkleRoot, tallyMerkleRoot, epoch - 1)
      await waitForHash(tx1)
      // Propose vote2 to the Block Relay
      contest.proposeBlock(vote2, drMerkleRoot, tallyMerkleRoot, epoch - 1)
      // Propose for the second time vote2
      contest.proposeBlock(vote2, drMerkleRoot, tallyMerkleRoot, epoch - 1)
      // Let's wait unitl the next epoch so we can get the final result
      await contest.nextEpoch()
      // Now call the final result function to select the winner
      await contest.finalresult()
      // Concatenation of the blockhash and the epoch to check later if it's equal to the last beacon
      const concatenated = web3.utils.hexToBytes(vote2).concat(
        web3.utils.hexToBytes(
          web3.utils.padLeft(
            web3.utils.toHex(epoch - 1), 64
          )
        )
      )
      // Should be equal the last beacon to vote2, since is the most voted
      const beacon = await contest.getLastBeacon.call()
      assert.equal(beacon, web3.utils.bytesToHex(concatenated))
    })

    it("should detect there is been a tie and revert the post", async () => {
      // There are two blocks proposed once
      const block1 = "0x" + sha.sha256("fir vote")
      const block2 = "0x" + sha.sha256("sec vote")
      const drMerkleRoot = 1
      const drMerkleRoot2 = 2
      const tallyMerkleRoot = 1
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      const epoch = await contest.updateEpoch.call()
      // Propose block1 to the Block Relay
      const tx1 = contest.proposeBlock(block1, drMerkleRoot, tallyMerkleRoot, epoch - 1)
      await waitForHash(tx1)
      // Propose block2 to the Block Relay
      const tx2 = contest.proposeBlock(block2, drMerkleRoot2, tallyMerkleRoot, epoch - 1)
      await waitForHash(tx2)
      // Let's wait unitl the next epoch so we can get the final result
      await contest.nextEpoch()
      // It reverts the finalResult() since it detects there is been a tie
      await truffleAssert.reverts(contest.finalresult(), "There is been a tie")
    })

    it("should revert because the block proposed is not in a valid epoch", async () => {
      const voteOne = "0x" + sha.sha256("propose")
      const drMerkleRoot = 1
      const tallyMerkleRoot = 1
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      const epoch = await contest.updateEpoch.call()
      // Propose the vote to the Block Relay
      // const tx = contest.proposeBlock(voteOne, drMerkleRoot, tallyMerkleRoot, epoch)
      // await waitForHash(tx)

      // If we call the finaResult function it should revert since for this epoch the votation epoch is not finished
      await truffleAssert.reverts(contest.proposeBlock(voteOne, drMerkleRoot, tallyMerkleRoot, epoch),
        "You are proposisng a block for a non valid epoch")
    })

    it("should set the winner to 0 after calling the final result", async () => {
      // the blockhash we want to propose
      const vote = "0x" + sha.sha256("the vote to propose")
      const vote2 = "0x" + sha.sha256("the second vote to propose")
      const vote3 = "0x" + sha.sha256("the third vote to propose")
      const drMerkleRoot = 1
      const tallyMerkleRoot = 1
      let setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      let epoch = await contest.updateEpoch.call()
      // Propose the vote to the Block Relay
      const tx = contest.proposeBlock(vote, drMerkleRoot, tallyMerkleRoot, epoch - 1)
      await waitForHash(tx)
      // Let's wait unitl the next epoch so we can get the final result
      setEpoch = contest.setEpoch(89160)
      await waitForHash(setEpoch)
      epoch = await contest.updateEpoch.call()
      // Call the Final Result
      const tx2 = contest.proposeBlock(vote2, drMerkleRoot, tallyMerkleRoot, epoch - 1)
      await waitForHash(tx2)
      // Wait another epoch
      setEpoch = contest.setEpoch(89161)
      await waitForHash(setEpoch)
      epoch = await contest.updateEpoch.call()
      const tx3 = contest.proposeBlock(vote3, drMerkleRoot, tallyMerkleRoot, epoch - 1)
      await waitForHash(tx3)
      // Call again the final result
      // await contest.finalresult()
      // Concatenation of the blockhash and the epoch=1 to check later if it's equal to the last beacon
      const concatenated = web3.utils.hexToBytes(vote2).concat(
        web3.utils.hexToBytes(
          web3.utils.padLeft(
            web3.utils.toHex(epoch - 2), 64
          )
        )
      )

      // Should be equal the last beacon
      const beacon = await contest.getLastBeacon.call()

      assert.equal(beacon, web3.utils.bytesToHex(concatenated))
    })
  })
})

const waitForHash = txQ =>
  new Promise((resolve, reject) =>
    txQ.on("transactionHash", resolve).catch(reject)
  )
