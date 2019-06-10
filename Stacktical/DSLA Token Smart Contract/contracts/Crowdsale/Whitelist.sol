pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
  * @title Whitelist
  * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
  * This simplifies the implementation of "user permissions".
  */
contract Whitelist is Ownable {
    // Whitelisted address
    mapping(address => bool) public whitelist;

    event AddedBeneficiary(address indexed _beneficiary);
    event RemovedBeneficiary(address indexed _beneficiary);

    /**
      * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
      * @param _beneficiaries Addresses to be added to the whitelist
      */
    function addAddressToWhitelist(address[] _beneficiaries) public onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;

            emit AddedBeneficiary(_beneficiaries[i]);
        }
    }

    /**
      * @dev Adds list of address to whitelist. Not overloaded due to limitations with truffle testing.
      * @param _beneficiary Address to be added to the whitelist
      */
    function addToWhitelist(address _beneficiary) public onlyOwner {
        whitelist[_beneficiary] = true;

        emit AddedBeneficiary(_beneficiary);
    }

    /**
      * @dev Removes single address from whitelist.
      * @param _beneficiary Address to be removed to the whitelist
      */
    function removeFromWhitelist(address _beneficiary) public onlyOwner {
        whitelist[_beneficiary] = false;

        emit RemovedBeneficiary(_beneficiary);
    }
}
