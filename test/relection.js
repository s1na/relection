const Relection = artifacts.require('Relection')
const RelectionMock = artifacts.require('RelectionMock')

const ZERO_ADDR = '0x0000000000000000000000000000000000000000'

contract('Relection', async (accounts) => {
  let instance
  let r1 = accounts[1]
  let r2 = accounts[2]

  before(async () => {
    instance = await RelectionMock.new()

    // Set "random" seed for blocknumbers
    await instance.setSeed(4, 0)
    await instance.setSeed(9, 0)
    await instance.setSeed(14, 0)
  })

  it('should have no relayers initially', async () => {
    let relayersCount = await instance.relayersCount.call()
    assert.equal(relayersCount, 0)
  })

  it('should not elect non-registered relayer', async () => {
    let elect = await instance.getElect()
    assert.equal(elect, ZERO_ADDR)

    try {
      await instance.isElected.call(r1)
      assert.fail('Expected revert not received')
    } catch (e) {
      const revertFound = e.message.search('revert') >= 0
      assert(revertFound, `Expected "revert", got ${e} instead`)
    }
  })

  it('should not register with insufficient deposit', async () => {
    try {
      await instance.register({ from: r1, value: web3.utils.toWei('0.5', 'ether') })
      assert.fail('Expected revert not received')
    } catch (e) {
      const revertFound = e.message.search('revert') >= 0
      assert(revertFound, `Expected "revert", got ${e} instead`)
    }
  })

  it('should register', async () => {
    await instance.setBlockNumber(7)
    let tx = await instance.register({ from: r1, value: web3.utils.toWei('1', 'ether') })
    let activeSince = tx.logs[0].args.activeSince.toNumber()
    assert.equal(activeSince, 10)

    let balance = await web3.eth.getBalance(instance.address)
    assert.equal(balance, web3.utils.toWei('1', 'ether'))

    let relayersCount = await instance.relayersCount.call()
    assert.equal(relayersCount, 1)

    let relayer = await instance.relayerArray(0)
    assert.equal(relayer, r1)
  })

  it('should not be elected until next period', async () => {
    await instance.setBlockNumber(9)

    let elect = await instance.getElect()
    assert(elect, ZERO_ADDR)

    let ok = await instance.isElected.call(r1)
    assert.isFalse(ok)
  })

  it('should elect relayer in the next period', async () => {
    await instance.setBlockNumber(10)

    let elect = await instance.getElect()
    assert.equal(elect, r1)

    let ok = await instance.isElected.call(r1)
    assert.isTrue(ok)
  })

  it('should deregister', async () => {
    await instance.deregister({ from: r1 })
  })

  it('should remain elect before deactivation', async () => {
    await instance.setBlockNumber(14)
    let elect = await instance.getElect()
    assert(elect, r1)
  })

  it('should not withdraw before deactivation', async () => {
    await instance.setBlockNumber(14)
    try {
      await instance.withdraw({ from: r1 })
      assert.fail('Expected revert not received')
    } catch (e) {
      const revertFound = e.message.search('revert') >= 0
      assert(revertFound, `Expected "revert", got ${e} instead`)
    }
  })

  it('should not be elected after deactivation', async () => {
    await instance.setBlockNumber(15)
    let elect = await instance.getElect()
    assert(elect, ZERO_ADDR)
  })

  it('should withdraw after deactivation', async () => {
    await instance.setBlockNumber(15)
    await instance.withdraw({ from: r1 })

    let balance = await web3.eth.getBalance(instance.address)
    assert.equal(balance, web3.utils.toWei('0', 'ether'))

    let relayer = await instance.relayerArray.call(0)
    assert.equal(relayer, ZERO_ADDR)
  })

  it('should not activate when registering two blocks before next period', async () => {
    await instance.setBlockNumber(8)
    let tx = await instance.register({ from: r2, value: web3.utils.toWei('1', 'ether') })
    let activeSince = tx.logs[0].args.activeSince.toNumber()
    assert.equal(activeSince, 15)
  })
})

contract('Relection multiple relayers', async (accounts) => {
  let instance
  let relayers = [accounts[1], accounts[2], accounts[3]]

  before(async () => {
    instance = await RelectionMock.new()
  })

  it('should register relayers', async () => {
    for (let i = 0; i < relayers.length; i++) {
      let tx = await instance.register({ from: relayers[i], value: web3.utils.toWei('1', 'ether') })
      let activeSince = tx.logs[0].args.activeSince.toNumber()
      assert.equal(activeSince, 5)
    }

    let balance = await web3.eth.getBalance(instance.address)
    assert.equal(balance, web3.utils.toWei(relayers.length.toString(), 'ether'))

    let relayersCount = await instance.relayersCount.call()
    assert.equal(relayersCount, relayers.length)
  })

  it('should elect relayer for period length', async () => {
    // Mocked contract allows us to pre-specify the seed for
    // given block numbers. For example, simulate blockhash(4) == 1.
    let seeds = { 4: 1, 9: 0, 14: 2 }
    for (let k in seeds) {
      await instance.setSeed(k, seeds[k])
    }

    let blockNum = 5
    for (let i = 0; i < 15; i++) {
      // Set block number on mocked contract
      await instance.setBlockNumber(blockNum)

      // Index of relayer who is elected during this block
      let elected = seeds[(await instance.getPeriodStart()).toNumber() - 1]

      // Only one relayer should be elected
      let ok = await instance.isElected.call(relayers[elected])
      assert.isTrue(ok)
      ok = await instance.isElected.call(relayers[(elected + 1) % 3])
      assert.isFalse(ok)
      ok = await instance.isElected.call(relayers[(elected + 2) % 3])
      assert.isFalse(ok)
    }
  })
})
