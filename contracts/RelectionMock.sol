pragma solidity ^0.4.24;

import "./Relection.sol";

contract RelectionMock is Relection {
  struct Seed {
    uint256 value;
    bool isSet;
  }

  uint256 blockNum;
  mapping(uint256 => Seed) seeds;

  function setSeed(uint256 _blockNum, uint256 seed) external {
    seeds[_blockNum] = Seed(seed, true);
  }

  function getSeed(uint256 _blockNum) internal view returns (uint256) {
    require(seeds[_blockNum].isSet);
    return seeds[_blockNum].value; 
  }

  function setBlockNumber(uint256 _blockNum) external {
    blockNum = _blockNum;
  }

  function getBlockNumber() internal view returns (uint256) {
    return blockNum;
  }
}
