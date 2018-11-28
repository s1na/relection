pragma solidity ^0.4.24;

contract Relection {
  event Registered(address addr, uint256 activeSince);

  struct Relayer {
    uint256 registrationTime;
    uint256 deposit;
    // Block number after which relayer is considered for election
    uint256 activeSince;
    // Block number after which relayer won't be considered for election
    uint256 deactiveSince;
  }

  mapping (address => Relayer) public relayers;
  address[] public relayerArray;

  // Amount of stake required on registration.
  uint256 constant STAKE_AMOUNT = 1 ether;

  // Length of period during which a relayer is allowed to submit.
  uint256 constant PERIOD_LENGTH = 5;

  modifier isRegistered(address _relayer) {
    require(relayers[_relayer].registrationTime != 0, "Relayer not registered");
    _;
  }

  /**
   * @dev Registers a relayer, if enough stake is deposited.
   */
  function register() public payable {
    require(relayers[msg.sender].registrationTime == 0, "Relayer already registered");
    require(msg.value == STAKE_AMOUNT, "Incorrect deposit value");

    // Consider relayer for election since next period
    uint256 activeSince = getPeriodStart() + PERIOD_LENGTH;
    // To prevent miners from withholding block to increase their
    // chance of being elected, make sure registration happens at
    // least 2 blocks before next period start.
    if (getBlockNumber() >= activeSince - 2) {
      activeSince += PERIOD_LENGTH;
    }

    Relayer memory r = Relayer(now, msg.value, activeSince, 0);
    relayers[msg.sender] = r;
    relayerArray.push(msg.sender);

    emit Registered(msg.sender, activeSince);
  }

  /**
   * @dev Returns true if relayer is elected.
   * @param _addr Address of relayer
   */
  function isElected(address _addr) public view isRegistered(_addr) returns (bool) {
    address elected = getElect();
    return _addr == elected;
  }

  /**
   * @dev Returns currently elected relayer, or address(0)
   *      if no relayer is elected.
   */
  function getElect() public view returns (address) {
    if (relayerArray.length == 0) {
      return address(0);
    }

    uint256 periodStart = getPeriodStart();
    uint256 seed = getSeed(periodStart - 1);
    uint256 i = seed % relayerArray.length;

    // Skip relayers starting from index i to find
    // an active candidate.
    for (uint256 j = 0; j < relayerArray.length; j++) {
      address addr = relayerArray[(i + j) % relayerArray.length];
      Relayer storage r = relayers[addr];
      if (r.registrationTime == 0) {
        continue;
      }
      if (getBlockNumber() < r.activeSince) {
        continue;
      }
      if (r.deactiveSince != 0 && getBlockNumber() >= r.deactiveSince) {
        continue;
      }

      return addr;
    }

    return address(0);
  }

  /**
   * @dev Marks relayer to be deactivated after the current period.
   *      Relayer has to then call withdraw to reclaim their deposit.
   */
  function deregister() public isRegistered(msg.sender) {
    Relayer storage r = relayers[msg.sender];
    require(r.deactiveSince == 0, "Relayer has been already deregistered");

    uint256 deactiveSince = getPeriodStart() + PERIOD_LENGTH;
    r.deactiveSince = deactiveSince;
  }

  /**
   * @dev Reclaims relayer's deposit if they are deactivated.
   */
  function withdraw() public isRegistered(msg.sender) {
    Relayer storage r = relayers[msg.sender];
    require(r.deactiveSince != 0, "Relayer hasn't deregistered");
    require(getBlockNumber() >= r.deactiveSince, "Relayer hasn't been deactivated yet");

    msg.sender.transfer(r.deposit);

    uint256 i = relayerIndex(msg.sender);
    delete relayers[msg.sender];
    delete relayerArray[i];
  }

  /**
   * @dev Returns start of the current period.
   */
  function getPeriodStart() public view returns (uint256) {
    uint256 bn = getBlockNumber();
    uint256 blockInPeriod = bn % PERIOD_LENGTH;
    return bn - blockInPeriod;
  }

  /**
   * @dev Returns number of relayers.
   */
  function relayersCount() public view returns (uint256) {
    return relayerArray.length;
  }

  function getBlockNumber() internal view returns (uint256) {
    return block.number;
  }

  function getSeed(uint256 blockNum) internal view returns (uint256) {
    return uint256(blockhash(blockNum));
  }

  function relayerIndex(address _addr) internal view returns (uint256) {
    uint256 i = 0;
    while (relayerArray[i] != _addr) {
      i++;
    }
    return i;
  }
}
