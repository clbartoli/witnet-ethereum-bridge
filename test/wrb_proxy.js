const truffleAssert = require("truffle-assertions")
const WitnetRequestsBoardV1 = artifacts.require("WitnetRequestsBoardV1")
const WitnetRequestsBoardV2 = artifacts.require("WitnetRequestsBoardV2")
const WitnetRequestsBoardProxy = artifacts.require("WitnetRequestsBoardProxy")
const MockBlockRelay = artifacts.require("MockBlockRelay")

contract("Witnet Requests Board Proxy", accounts => {
  describe("Witnet Requests Board Proxy test suite", () => {
    let blockRelay
    let wrbInstance1
    let wrbInstance2
    let wrbProxy

    before(async () => {
        blockRelay = await MockBlockRelay.new({
            from: accounts[0],
          })
        wrbInstance1 = await WitnetRequestsBoardV1.new(blockRelay.address , 1 , {
        from: accounts[0],
      })
        wrbInstance2 = await WitnetRequestsBoardV2.new(blockRelay.address , 1 , {
        from: accounts[0],
      })
        wrbProxy = await WitnetRequestsBoardProxy.new(wrbInstance1.address, {
        from: accounts[0],
      })
    })

    it("should revert when trying to upgrade the same WRB", async () => {
      // It should revert because the WRB to be upgrated is already in use
      await truffleAssert.reverts(wrbProxy.upgradeWitnetRequestsBoard(wrbInstance1.address),  "The provided Witnet Requests Board instance address is already in use")
    })

    it("should post a data request and read the result", async () => {
        // Take current balance
        // var account1 = accounts[0]
        // const actualBalance1 = await web3.eth.getBalance(account1)
  
        // const drBytes = web3.utils.fromAscii("This is a DR")
        // const drBytes2 = web3.utils.fromAscii("This is a second DR")
  
        // const halfEther = web3.utils.toWei("0.5", "ether")
  
        // // Post first data request
        // const tx1 = wrbProxy.postDataRequest(drBytes, halfEther, {
        //   from: accounts[0],
        //   value: web3.utils.toWei("1", "ether"),
        // })

        // let a = tx1
        // const txHash1 = await waitForHash(tx1)
        // const txReceipt1 = await web3.eth.getTransactionReceipt(txHash1)
        // const id1 = txReceipt1.logs[0].data
  
        // // Post second data request
        // const tx2 = wrbInstance.postDataRequest(drBytes2, 0)
        // const txHash2 = await waitForHash(tx2)
        // const txReceipt2 = await web3.eth.getTransactionReceipt(txHash2)
        // const id2 = txReceipt2.logs[0].data
  
        // // Read both
        // const readDrBytes = await wrbInstance.readDataRequest.call(id1)
        // const readDrBytes2 = await wrbInstance.readDataRequest.call(id2)
  
        // // Assert correct balances
        // const afterBalance1 = await web3.eth.getBalance(account1)
        // const contractBalanceAfter = await web3.eth.getBalance(
        //   wrbInstance.address
        // )
  
        // assert(parseInt(afterBalance1, 10) < parseInt(actualBalance1, 10))
        // assert.equal(web3.utils.toWei("1", "ether"), contractBalanceAfter)
  
        // assert.equal(drBytes, readDrBytes)
        // assert.equal(drBytes2, readDrBytes2)
      })

    // it("should revert when trying to verify dr in blockRelayInstance", async () => {
    //     // Set the wrbIntance2 to be the WRB in the proxy contract
    //     await wrbProxy.upgradeWitnetRequestsBoard(wrbInstance2.address)
    //     // It should revert when trying to upgrade the wrb since wrbInstance2 is not upgradable
    //     await truffleAssert.reverts(wrbProxy.upgradeWitnetRequestsBoard(wrbInstance1.address),  "The upgrade has been rejected by the current implementation")
    //   })
  })
})
