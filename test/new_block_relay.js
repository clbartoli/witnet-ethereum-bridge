const NewBlockRelay = artifacts.require("NewBlockRelay")
const sha = require("js-sha256")
const NewBRTestHelper = artifacts.require("NewBRTestHelper")
const truffleAssert = require("truffle-assertions")
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
      // Fix the timestamp in witnet to be 89159
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      const epoch = await contest.updateEpoch.call()
      // Update the ABS to be included
      await contest.pushActivity(1)
      // Propose the vote to the Block Relay
      await contest.setAbsIdentities(1)
      const tx = contest.proposeBlock(vote, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      await waitForHash(tx)
      // Wait unitl the next epoch to get the final result
      await contest.nextEpoch()
      // Call the Final Result
      await contest.finalresult(0)
      // Concatenation of the blockhash and the epoch-1 to check later if it's equal to the last beacon.blockHash
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
      const vote1 = "0x" + sha.sha256("the vote to propose")
      const vote2 = "0x" + sha.sha256("second vote")
      const drMerkleRoot = 1
      const tallyMerkleRoot = 1
      // Fix the timestamp in witnet to be 89159
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      const epoch = await contest.updateEpoch.call()
      // Update the ABS to be included
      await contest.pushActivity(1)
      await contest.setAbsIdentities(3)
      // Propose the vote to the Block Relay
      const tx = contest.proposeBlock(vote1, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      await waitForHash(tx)
      const tx2 = contest.proposeBlock(vote1, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      await waitForHash(tx2)
      const tx3 = contest.proposeBlock(vote1, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      await waitForHash(tx3)
      // Wait unitl the next epoch
      await contest.nextEpoch()
      // Propose another block in the new epoch and so post the previous one
      contest.proposeBlock(vote2, epoch, drMerkleRoot, tallyMerkleRoot, 1)
      // Concatenation of the blockhash and the epoch -1 to check later if it's equal to the last beacon
      const concatenated = web3.utils.hexToBytes(vote1).concat(
        web3.utils.hexToBytes(
          web3.utils.padLeft(
            web3.utils.toHex(epoch - 1), 64
          )
        )
      )
      // Should be equal the last beacon
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
      // Fix the timestamp in witnet to be 89159
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      const epoch = await contest.updateEpoch.call()
      // Update the ABS to be included
      await contest.pushActivity(1)
      // Propose vote1 to the Block Relay
      const tx1 = contest.proposeBlock(vote1, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      await waitForHash(tx1)
      // Propose vote2 to the Block Relay
      contest.proposeBlock(vote2, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      // Propose for the second time vote2
      contest.proposeBlock(vote2, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      // Wait unitl the next epoch so to get the final result
      await contest.nextEpoch()
      // Now call the final result function to select the winner
      await contest.finalresult(0)
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

    /*it("should revert if not achieved 2/3 of the ABS", async () => {
      // the blockhash we want to propose
      const vote = "0x" + sha.sha256("the vote to propose")
      const drMerkleRoot = 1
      const tallyMerkleRoot = 1
      // Fix the timestamp in witnet to be 89159
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      const epoch = await contest.updateEpoch.call()
      // Set the abs to have 3 identities
      await contest.setAbsIdentities(3)
      // Propose the vote to the Block Relay
      const tx = contest.proposeBlock(vote, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      await waitForHash(tx)
      // Wait unitl the next epoch to get the final result
      await contest.nextEpoch()
      // Call the Final Result
      //await contest.finalresult()
      // Concatenation of the blockhash and the epoch-1 to check later if it's equal to the last beacon.blockHash
      const concatenated = web3.utils.hexToBytes(vote).concat(
        web3.utils.hexToBytes(
          web3.utils.padLeft(
            web3.utils.toHex(epoch - 1), 64
          )
        )
      )
      // Should revert when posting a new block becouse the winning vote has only recieved 1 vote but there 3 members of the ABS
      await truffleAssert.reverts(contest.finalresult(0), "Not achieved the minimum number of votes")
    })*/

    it("should set the previos block to pending when not achieved 2/3 of the ABS", async () => {
      // the blockhash we want to propose
      const vote = "0x" + sha.sha256("the vote to propose")
      const drMerkleRoot = 1
      const tallyMerkleRoot = 1
      // Fix the timestamp in witnet to be 89159
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      const epoch = await contest.updateEpoch.call()
      // Update the ABS to be included
      await contest.pushActivity(1)
      // Set the abs to have 3 identities
      await contest.setAbsIdentities(3)
      // Propose the vote to the Block Relay
      const tx = contest.proposeBlock(vote, epoch-1, drMerkleRoot, tallyMerkleRoot, 0)
      await waitForHash(tx)
      // Wait unitl the next epoch to get the final result
       await contest.nextEpoch()
      // Call the Final Result
      await contest.finalresult(0)
      // Concatenation of the blockhash and the epoch-1 to check later if it's equal to the last beacon.blockHash
      const concatenated = web3.utils.hexToBytes(vote).concat(
        web3.utils.hexToBytes(
          web3.utils.padLeft(
            web3.utils.toHex(epoch - 1), 64
          )
        )
      )
      const epochStatus = await contest.checkStatusPending.call()
      assert.equal(epochStatus, true)
    })


    /*it("should detect there has been a tie and just set the epochStatus equal Pending", async () => {
      // There are two blocks proposed once
      const vote1 = "0x" + sha.sha256("first vote")
      const vote2 = "0x" + sha.sha256("second vote")
      const drMerkleRoot = 1
      const drMerkleRoot2 = 2
      const tallyMerkleRoot = 1
      await contest.setAbsIdentities(3)
      // Fix the timestamp in witnet to be 89159
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      const epoch = await contest.updateEpoch.call()
      // Update the ABS to be included
      await contest.pushActivity(1)
      // Propose block1 to the Block Relay
      const tx1 = contest.proposeBlock(vote1, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      await waitForHash(tx1)
      // Propose block2 to the Block Relay
      const tx2 = contest.proposeBlock(vote2, epoch - 1, drMerkleRoot2, tallyMerkleRoot, 0)
      await waitForHash(tx2)
      // Let's wait unitl the next epoch so we can get the final result
      await contest.nextEpoch()
      await contest.finalresult(0)
      const epochStatus = await contest.checkStatusPending.call()
      assert.equal(epochStatus, true)
      // It reverts the finalResult() since it detects there is been a tie
      // await truffleAssert.reverts(contest.finalresult(), "There has been a tie")
    })*/

    it("should detect there has been a tie and just set the epochStatus equal Pending", async () => {
      // There are two blocks proposed once
      const vote1 = "0x" + sha.sha256("first vote")
      const vote2 = "0x" + sha.sha256("second vote")
      const drMerkleRoot = 1
      const drMerkleRoot2 = 2
      const tallyMerkleRoot = 1
      await contest.setAbsIdentities(3)
      // Fix the timestamp in witnet to be 89159
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      const epoch = await contest.updateEpoch.call()
      // Update the ABS to be included
      await contest.pushActivity(1)
      // Propose block1 to the Block Relay
      const tx1 = contest.proposeBlock(vote1, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      await waitForHash(tx1)
      // Propose block2 to the Block Relay
      const tx2 = contest.proposeBlock(vote2, epoch - 1, drMerkleRoot2, tallyMerkleRoot, 0)
      await waitForHash(tx2)
      // Let's wait unitl the next epoch so we can get the final result
      await contest.nextEpoch()
      await contest.finalresult(0)
      contest.proposeBlock(vote2, epoch, drMerkleRoot2, tallyMerkleRoot, vote2)
      contest.proposeBlock(vote2, epoch, drMerkleRoot2, tallyMerkleRoot, vote2)
      contest.proposeBlock(vote2, epoch, drMerkleRoot2, tallyMerkleRoot, vote2)
      await contest.nextEpoch()
      await contest.finalresult(vote2)

    })

    /*it("should detect there has been a tie and just set the epochStatus equal Pending", async () => {
      // There are two blocks proposed once
      const vote1 = "0x" + sha.sha256("first vote")
      const vote2 = "0x" + sha.sha256("second vote")
      const drMerkleRoot = 1
      const drMerkleRoot2 = 2
      const tallyMerkleRoot = 1
      await contest.setAbsIdentities(3)
      // Fix the timestamp in witnet to be 89159
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      const epoch = await contest.updateEpoch.call()
      // Propose block1 to the Block Relay
      const tx1 = contest.proposeBlock(vote1, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      await waitForHash(tx1)
      // Propose block2 to the Block Relay
      const tx2 = contest.proposeBlock(vote2, epoch - 1, drMerkleRoot2, tallyMerkleRoot, 0)
      await waitForHash(tx2)
      // Let's wait unitl the next epoch so we can get the final result
      await contest.nextEpoch()
      await contest.finalresult(0)
      contest.proposeBlock(vote2, epoch, drMerkleRoot2, tallyMerkleRoot, vote2)
      contest.proposeBlock(vote2, epoch, drMerkleRoot2, tallyMerkleRoot, vote2)
      contest.proposeBlock(vote2, epoch, drMerkleRoot2, tallyMerkleRoot, vote2)
      await contest.nextEpoch()
      await contest.finalresult(vote2)

    })*/

    it("should revert because the block proposed is not for a valid epoch", async () => {
      const vote = "0x" + sha.sha256("vote proposed")
      const drMerkleRoot = 1
      const tallyMerkleRoot = 1
      // Fix the timestamp in witnet to be 89159
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      const epoch = await contest.updateEpoch.call()
      // Update the ABS to be included
      await contest.pushActivity(1)
      await truffleAssert.reverts(contest.proposeBlock(vote, epoch, drMerkleRoot, tallyMerkleRoot, 0),
        "Proposing a block for a non valid epoch")
    })

    it("should set the candidates array to 0 after posting a block", async () => {
      // the blockhash we want to propose
      const vote = "0x" + sha.sha256("the vote to propose")
      const drMerkleRoot = 1
      const tallyMerkleRoot = 1
      // Fix the timestamp in witnet to be 89159
      let setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      let epoch = await contest.updateEpoch.call()
      // Update the ABS to be included
      await contest.pushActivity(1)
      // Propose the vote to the Block Relay
      const tx = contest.proposeBlock(vote, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      await waitForHash(tx)
      // Fix the timestamp to be one epoch later
      setEpoch = contest.setEpoch(89160)
      await waitForHash(setEpoch)
      epoch = await contest.updateEpoch.call()
      // Call the final result so it posts the block header to the block relay and sets the candidate array to 0
      await contest.finalresult(0)
      // The candidates array
      const candidate = await contest.getCandidates.call()
      // Assert the candidates array is equal to 0
      assert.equal(0, candidate)
    })

    /*it("should save different candidates for different epochs", async () => {
      // There are two blocks proposed once
      const vote1 = "0x" + sha.sha256("first vote")
      console.log(vote1)
      //const vote2 = "0x" + sha.sha256("second vote")
      const drMerkleRoot = 1
      //const drMerkleRoot2 = 2
      const tallyMerkleRoot = 1
      // Fix the timestamp in witnet to be 89159
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      const epoch = await contest.updateEpoch.call()
      // Update the ABS to be included
      await contest.pushActivity(1)
      // Propose block1 to the Block Relay
      const tx1 = contest.proposeBlock(vote1, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      await waitForHash(tx1)
      const winnerProposal = await contest.winnerProposed(epoch)
      //await waitForHash(tx)
      //const winnerProposal = await contest.getWinnerProposal.call()
      //assert.equal(vote1, web3.utils.bytesToHex(winnerProposal))
      // Propose block2 to the Block Relay
      //const tx2 = contest.proposeBlock(vote2, epoch - 1, drMerkleRoot2, tallyMerkleRoot)
      //await waitForHash(tx2)
      // Let's wait unitl the next epoch so we can get the final result
      await contest.nextEpoch()
      const newEpoch = await contest.updateEpoch.call()
      const winnerProposal2 = await contest.winnerProposed(newEpoch)
      //await contest.winnerProposed(newEpoch-1)
      //console.log(web3.utils.bytesToHex(winnerProposal2))
      // It reverts the finalResult() since it detects there is been a tie
      //await truffleAssert.reverts(contest.finalresult(), "There has been a tie")
      assert.notEqual(winnerProposal, winnerProposal2)
    })*/

    it("should save different candidates for different epochs", async () => {
      // There are two blocks proposed once
      const vote1 = "0x" + sha.sha256("first vote")
      const vote2 = "0x" + sha.sha256("second vote")
      const drMerkleRoot = 1
      //const drMerkleRoot2 = 2
      const tallyMerkleRoot = 1
      // Fix the timestamp in witnet to be 89159
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      const epoch = await contest.updateEpoch.call()
      // Update the ABS to be included
      await contest.pushActivity(1)
      // Propose block1 to the Block Relay
      const tx1 = contest.proposeBlock(vote1, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      await waitForHash(tx1)
      const tx2 = contest.proposeBlock(vote2, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      const winnerProposal = await contest.winnerProposed(epoch)
      //await waitForHash(tx)
      //const winnerProposal = await contest.getWinnerProposal.call()
      //assert.equal(vote1, web3.utils.bytesToHex(winnerProposal))
      // Propose block2 to the Block Relay
      //const tx2 = contest.proposeBlock(vote2, epoch - 1, drMerkleRoot2, tallyMerkleRoot)
      //await waitForHash(tx2)
      // Let's wait unitl the next epoch so we can get the final result
      await contest.nextEpoch()
      const newEpoch = await contest.updateEpoch.call()
      const winnerProposal2 = await contest.winnerProposed(newEpoch)
      //await contest.winnerProposed(newEpoch-1)
      //console.log(web3.utils.bytesToHex(winnerProposal2))
      // It reverts the finalResult() since it detects there is been a tie
      //await truffleAssert.reverts(contest.finalresult(), "There has been a tie")
      assert.notEqual(winnerProposal, winnerProposal2)
    })

    it("should propose a block, propose another one and two epochs later and finalize the three", async () => {
      // The idea is that after two epoch with no consesus, when in epoch n the consensus is achived then epochs n-1 and n-2 are finalized as well
      const vote0 = "0x" + sha.sha256("null vote")
      const vote1 = "0x" + sha.sha256("first vote")
      const vote2 = "0x" + sha.sha256("second vote")
      const vote3 = "0x" + sha.sha256("third vote")
      const drMerkleRoot = 1
      const tallyMerkleRoot = 1
      // Fix the timestamp in witnet to be 89159
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      let epoch = await contest.updateEpoch.call()
      // Update the ABS to be included
      await contest.pushActivity(1)
      // Set the ABS to have 3 members
      await contest.setAbsIdentities(3)
      const tx = contest.proposeBlock(vote0, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      await waitForHash(tx)
      const tx1 = contest.proposeBlock(vote0, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      await waitForHash(tx1)
      const tx2 = contest.proposeBlock(vote0, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      await waitForHash(tx2)
      await contest.nextEpoch()
      epoch = await contest.updateEpoch.call()
      // Propose vote1 to the Block Relay
      const tx3 = contest.proposeBlock(vote1, epoch - 1, drMerkleRoot, tallyMerkleRoot, vote0)
      await waitForHash(tx3)
      // Wait for next epoch
      await contest.nextEpoch()
      epoch = await contest.updateEpoch.call()
      // Propose vote2 to the BlockRelay
      const tx7 = contest.proposeBlock(vote2, epoch - 1, drMerkleRoot, tallyMerkleRoot, vote1)
      await waitForHash(tx7)
      // Wait for next epoch
      await contest.nextEpoch()
      epoch = await contest.updateEpoch.call()
      // Propose 3 times vote 3 to the BlockRelay
      const tx4 =contest.proposeBlock(vote3, epoch - 1, drMerkleRoot, tallyMerkleRoot, vote2)
      await waitForHash(tx4)
      const tx5 = contest.proposeBlock(vote3, epoch - 1, drMerkleRoot, tallyMerkleRoot, vote2)
      await waitForHash(tx5)
      const tx6 = contest.proposeBlock(vote3, epoch - 1, drMerkleRoot, tallyMerkleRoot, vote2)
      await waitForHash(tx6)
      // Wait for next epoch
      await contest.nextEpoch()
      epoch = await contest.updateEpoch.call()
      // Propose a random vote just to finalize previous epochs
      await contest.proposeBlock(vote2, epoch - 1, drMerkleRoot, tallyMerkleRoot, vote3)
      // Now we want to check that 
      
      const epochStatus = await contest.checkStatusFinalized.call()
      assert.equal(epochStatus, true)
      // assert.notEqual(winnerProposal, winnerProposal2)
    })

    /*it("should propose 2 blocks, have a tie and then finalize the voting with a new block", async () => {
      // The are to votes, vote1, voted once and vote 2 voted twice.
      // It should win vote2 and so be posted in the Block Relay
      const vote1 = "0x" + sha.sha256("first vote")
      const vote2 = "0x" + sha.sha256("second vote")
      const drMerkleRoot = 0
      const tallyMerkleRoot = 0
      // Fix the timestamp in witnet to be 89159
      const setEpoch = contest.setEpoch(89159)
      await waitForHash(setEpoch)
      const epoch = await contest.updateEpoch.call()
      // Update the ABS to be included
      await contest.pushActivity(1)
      // Propose vote1 to the Block Relay
      const tx1 = contest.proposeBlock(vote1, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      await waitForHash(tx1)
      // Propose vote2 to the Block Relay
      contest.proposeBlock(vote2, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      // Propose for the second time vote2
      //contest.proposeBlock(vote2, epoch - 1, drMerkleRoot, tallyMerkleRoot, 0)
      // Wait unitl the next epoch so to get the final result
      await contest.nextEpoch()
      // Now call the final result function to select the winner
      
      // Concatenation of the blockhash and the epoch to check later if it's equal to the last beacon
      const concatenated = web3.utils.hexToBytes(vote2).concat(
        web3.utils.hexToBytes(
          web3.utils.padLeft(
            web3.utils.toHex(epoch - 1), 64
          )
        )
      )
      await contest.finalresult(vote2)
      await contest.nextEpoch()
      await contest.finalresult(vote2)

      // Should be equal the last beacon to vote2, since is the most voted
      const beacon = await contest.getLastBeacon.call()
      assert.equal(beacon, web3.utils.bytesToHex(concatenated))
    })*/
  })
})

const waitForHash = txQ =>
  new Promise((resolve, reject) =>
    txQ.on("transactionHash", resolve).catch(reject)
  )
