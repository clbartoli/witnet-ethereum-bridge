const truffleAssert = require("truffle-assertions")
const WitnetRequestsBoardV1 = artifacts.require("WitnetRequestsBoardV1")
const WitnetRequestsBoardV2 = artifacts.require("WitnetRequestsBoardV2")
const WitnetRequestsBoardV3 = artifacts.require("WitnetRequestsBoardV3")
// const WitnetRequestsBoardProxy = artifacts.require("WitnetRequestsBoardProxy")
const WrbProxyHelper = artifacts.require("WrbProxyTestHelper")
const MockBlockRelay = artifacts.require("MockBlockRelay")

contract("Witnet Requests Board Proxy", accounts => {
  describe("Witnet Requests Board Proxy test suite", () => {
    let blockRelay
    let wrbInstance1
    let wrbInstance2
    let wrbInstance3
    let wrbProxy

    before(async () => {
      blockRelay = await MockBlockRelay.new({
        from: accounts[0],
      })
      wrbInstance1 = await WitnetRequestsBoardV1.new(blockRelay.address, 1, {
        from: accounts[0],
      })
      wrbInstance2 = await WitnetRequestsBoardV2.new(blockRelay.address, 1, {
        from: accounts[0],
      })
      wrbInstance3 = await WitnetRequestsBoardV3.new(blockRelay.address, 1, {
        from: accounts[0],
      })
      wrbProxy = await WrbProxyHelper.new(wrbInstance1.address, {
        from: accounts[0],
      })
    })

    it("should revert when trying to upgrade the same WRB", async () => {
      // It should revert because the WRB to be upgrated is already in use
      await truffleAssert.reverts(wrbProxy.upgradeWitnetRequestsBoard(wrbInstance1.address),
        "The provided Witnet Requests Board instance address is already in use")
    })

    it("should post a data request and update the currentLastId", async () => {
      // The data request to be posted
      const drBytes = web3.utils.fromAscii("This is a DR")
      const halfEther = web3.utils.toWei("0.5", "ether")

      // Post the data request through the Proxy
      const tx1 = wrbProxy.postDataRequest(drBytes, halfEther, {
        from: accounts[0],
        value: web3.utils.toWei("1", "ether"),
      })
      const txHash1 = await waitForHash(tx1)
      const txReceipt1 = await web3.eth.getTransactionReceipt(txHash1)
      console.log(txReceipt1)
      // The id of the data request
      const id1 = txReceipt1.logs[0].data
      console.log(id1)

      // check the currentLastId has been updated in the Proxy when posting the data request
      assert.equal(true, await wrbProxy.checkLastId.call(id1))
    })

    it("should return the correposding controller of an id", async () => {
      // The data request to be posted
      const drBytes = web3.utils.fromAscii("This is a DR")
      const halfEther = web3.utils.toWei("0.5", "ether")

      // Post the data request through the Proxy
      const tx1 = wrbProxy.postDataRequest(drBytes, halfEther, {
        from: accounts[0],
        value: web3.utils.toWei("1", "ether"),
      })
      const txHash1 = await waitForHash(tx1)
      const txReceipt1 = await web3.eth.getTransactionReceipt(txHash1)

      // The id of the data request
      const id1 = txReceipt1.logs[0].data
      

      // Upgrade the WRB address to wrbInstance3
      await wrbProxy.upgradeWitnetRequestsBoard(wrbInstance3.address)
      // Get the address of the wrb form id1
      const wrb = await wrbProxy.getControllerAddress.call(id1)
    
      // It should be equal to the address of wrbInstance1
      assert.equal(wrb, wrbInstance1.address)
      assert.equal(await wrbProxy.getWrbAddress.call(), wrbInstance3.address)
    })

    it("should read the result", async () => {
      // The data request to be posted
      const drBytes = web3.utils.fromAscii("This is a DR")
      const halfEther = web3.utils.toWei("0.5", "ether")

      // Post the data request through the Proxy with result "hello"
      const tx2 = wrbProxy.postDataRequest(drBytes, halfEther, {
        from: accounts[0],
        value: web3.utils.toWei("1", "ether"),
      })
      const txHash2 = await waitForHash(tx2)
      const txReceipt2 = await web3.eth.getTransactionReceipt(txHash2)

      // The id of the data request
      const id2 = txReceipt2.logs[0].data
      console.log(id2)
      // await wrbProxy.upgradeWitnetRequestsBoard(wrbInstance3.address)
      const currentWrb = await wrbProxy.getCurrentController.call()
      console.log(currentWrb)
      const wrb = await wrbProxy.getControllerAddress.call(id2)
      console.log(wrb)
      console.log(wrbInstance1.address)
      console.log(wrbInstance3.address)
      // Read the result
      const result = await wrbProxy.readResult.call(id2)
      console.log(result)
      // await wrbProxy.readResult.call(id1)
      // assert.equal("hello", web3.utils.bytesToHex(result))
    })

    it("should upgrade the wrb address", async () => {
      // It should upgrade the WRB address
      await wrbProxy.upgradeWitnetRequestsBoard(wrbInstance2.address)
      const wrb = await wrbProxy.getWrbAddress.call()
      assert.equal(wrb, wrbInstance2.address)
    })

    it("should revert when trying to verify dr in blockRelayInstance", async () => {
      // Set the wrbIntance2 to be the WRB in the proxy contract
      // await wrbProxy.upgradeWitnetRequestsBoard(wrbInstance2.address)
      // It should revert when trying to upgrade the wrb since wrbInstance2 is not upgradable
      await truffleAssert.reverts(wrbProxy.upgradeWitnetRequestsBoard(wrbInstance1.address),
        "The upgrade has been rejected by the current implementation")
    })
  })
})

const waitForHash = txQ =>
  new Promise((resolve, reject) =>
    txQ.on("transactionHash", resolve).catch(reject)
  )
