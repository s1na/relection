pragma solidity ^0.4.24;

contract Relection {
  event Registered(address addr);

  struct Relayer {
    uint256 registrationTime;
    uint256 deposit;
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

    Relayer memory r = Relayer(now, msg.value);
    relayers[msg.sender] = r;
    relayerArray.push(msg.sender);

    emit Registered(msg.sender);
  }

  /**
   * @dev Returns true if relayer is elected.
   * @param _addr Address of relayer
   */
  function isElected(address _addr) public view isRegistered(_addr) returns (bool) {
    uint256 periodStart = getPeriodStart();
    uint256 seed = getSeed(periodStart - 1);
    uint256 i = seed % relayerArray.length;

    return _addr == relayerArray[i];
  }

  /**
   * @dev Delists relayer and returns their deposit.
   */
  function withdraw() public isRegistered(msg.sender) {
    msg.sender.transfer(relayers[msg.sender].deposit);

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
