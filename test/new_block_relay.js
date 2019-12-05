const NewBlockRelay = artifacts.require("NewBlockRelay")
const sha = require("js-sha256")
const truffleAssert = require("truffle-assertions")

contract("New block relay", accounts => {
    describe("New block relay test suite", () => {
      let newblockRelayInstance
      before(async () => {
        newblockRelayInstance = await NewBlockRelay(1568559600).new({
          from: accounts[0],
        })
      })
    
it("should propose a block", async () =>{
    NewBlockRelay.candidates
    let voteOne = "0x" + sha.sha256("first id")
    let voteTwo = "0x" + sha.sha256("second id")
    console.log(voteOne)
    console.log(voteTwo)
    let epoch = 0
    let drRoot = 1
    let merkleRoot = 1 
    let tx1 = newblockRelayInstance.proposeBlock(voteOne, drRoot, merkleRoot)
    //console.log(tx1)  
    
    await waitForHash(tx1)
    let concatenated = web3.utils.hexToBytes(voteOne).concat(
      web3.utils.hexToBytes(
        web3.utils.padLeft(
          web3.utils.toHex(epoch), 64
        )
      )
    )
    let tx3 = newblockRelayInstance.proposeBlock(voteTwo, drRoot, merkleRoot)
    let tx2 = newblockRelayInstance.proposeBlock(voteTwo, drRoot, merkleRoot)
    //console.log(tx1)  
    
    await waitForHash(tx2)
    let concatenated2 = web3.utils.hexToBytes(voteTwo).concat(
      web3.utils.hexToBytes(
        web3.utils.padLeft(
          web3.utils.toHex(epoch), 64
        )
      )
    )
    console.log(web3.utils.bytesToHex(concatenated2))
    let beacon = await newblockRelayInstance.getLastBeacon.call()
    assert.equal(beacon, web3.utils.bytesToHex(concatenated2))
})
it("should confirm the vote is a candidate", async () =>{
  let voteOne = "0x" + sha.sha256("firsts id")
  //let voteTwo = "0x" + sha.sha256("second id")
  console.log(voteOne)
  //console.log(voteTwo)
  let epoch = 0
  let drRoot = 1
  let merkleRoot = 1 
  let tx1 = newblockRelayInstance.proposeBlock(voteOne, drRoot, merkleRoot)
  //console.log(tx1)  
  await waitForHash(tx1)
  let candidate = newblockRelayInstance.candidates[0]
  console.log(candidate)
  //assert.equal(voteOne, web3.utils.bytesToHex(candidate))
})
it("should detect there is been a tie", async () =>{

})
it("should select the most voted block hash", async () =>{

})
})
})

const waitForHash = txQ =>
  new Promise((resolve, reject) =>
    txQ.on("transactionHash", resolve).catch(reject)
  )
