const Relection = artifacts.require('Relection')

contract('Relection', async (accounts) => {
  let instance

  before(async () => {
    instance = await Relection.new()
  })

  it('should have no relayers initially', async () => {
    let relayersCount = await instance.relayersCount.call()
    assert.equal(relayersCount, 0)
  })
})
