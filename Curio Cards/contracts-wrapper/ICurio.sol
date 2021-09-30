pragma solidity ^0.5.0;

// Curio is not quite ERC-20 compliant
interface ICurio {
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) external;
  function transfer(address _to, uint256 _value) external;
  function ipfs_hash() external view returns (string memory);
}
