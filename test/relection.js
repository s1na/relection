const Relection = artifacts.require('Relection')

const ZERO_ADDR = '0x0000000000000000000000000000000000000000'

contract('Relection', async (accounts) => {
  let instance
  let r1 = accounts[1]
  let r2 = accounts[2]

  before(async () => {
    instance = await Relection.new()
  })

  it('should have no relayers initially', async () => {
    let relayersCount = await instance.relayersCount.call()
    assert.equal(relayersCount, 0)
  })

  it('should not be able to submit with no relayers', async () => {
    try {
      await instance.canSubmit.call(r1, web3.utils.randomHex(32), { from: r1 })
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
    await instance.register({ from: r1, value: web3.utils.toWei('1', 'ether') })

    let balance = await web3.eth.getBalance(instance.address)
    assert.equal(balance, web3.utils.toWei('1', 'ether'))

    let relayersCount = await instance.relayersCount.call()
    assert.equal(relayersCount, 1)

    let relayer = await instance.relayerArray(0)
    assert.equal(relayer, r1)
  })

  it('should be able to submit', async () => {
    let ok = await instance.canSubmit.call(r1, web3.utils.randomHex(32), { from: r1 })
    assert.isTrue(ok)
  })

  it('should withdraw', async () => {
    await instance.withdraw({ from: r1 })

    let balance = await web3.eth.getBalance(instance.address)
    assert.equal(balance, web3.utils.toWei('0', 'ether'))

    let relayer = await instance.relayerArray.call(0)
    assert.equal(relayer, ZERO_ADDR)
  })
})
