pragma solidity ^0.4.24;

import "./Relection.sol";

contract RelectionMock is Relection {
  struct Seed {
    uint256 value;
    bool isSet;
  }

  uint256 blockNum;
  mapping(uint256 => mapping(bytes32 => Seed)) seeds;

  function setSeed(uint256 _blockNum, uint256 seed, bytes32 _salt) external {
    seeds[_blockNum][_salt] = Seed(seed, true);
  }

  function getSeed(uint256 _blockNum, bytes32 _salt) internal view returns (uint256) {
    require(seeds[_blockNum][_salt].isSet);
    return seeds[_blockNum][_salt].value;
  }

  function setBlockNumber(uint256 _blockNum) external {
    blockNum = _blockNum;
  }

  function getBlockNumber() internal view returns (uint256) {
    return blockNum;
  }
}
