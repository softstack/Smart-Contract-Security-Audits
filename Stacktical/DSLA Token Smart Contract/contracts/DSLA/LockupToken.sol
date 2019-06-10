pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/** @title LockupToken
  * @dev Extension of StandardToken that adds a lock-up period during which
  * the token won't be transferable (except by the owner of the contract)
  */
contract LockupToken is ERC20Burnable, Ownable {
    uint256 public releaseDate;
    address public owner;
    address public crowdsaleAddress;

    event CrowdsaleAddressSet(address _crowdsaleAddress);

    /**
      * @dev Constructor
      * @param _releaseDate The date from which users will be able to transfer
      * the token
      */
    constructor(uint256 _releaseDate) public {
        require(_releaseDate > block.timestamp);
        releaseDate = _releaseDate;
        owner = msg.sender;
    }

    /**
      * @dev Reverts if are not past the releaseDate or if the caller isn't the owner
      */
    modifier unlocked() {
        require(block.timestamp > releaseDate || msg.sender == owner || msg.sender == crowdsaleAddress);
        _;
    }

    /**
      * @dev Allows contract's owner to edit the date at which users are
      * allowed to trade their token
      * @param _newReleaseDate The release date that will replace the former one
      */
    function setReleaseDate(uint256 _newReleaseDate) public onlyOwner {
        require(block.timestamp < releaseDate);
        require(_newReleaseDate >= block.timestamp);

        releaseDate = _newReleaseDate;
    }

    /**
      * @dev NECESSARY: Allows contract's owner to set the address of the crowdsale's
      * contract. This is necessary so the token contract allows the crowdsale contract
      * to deal the tokens during lock-up period.
      * @param _crowdsaleAddress The address of the crowdsale contract
      */
    function setCrowdsaleAddress(address _crowdsaleAddress) public onlyOwner {
        crowdsaleAddress = _crowdsaleAddress;

        emit CrowdsaleAddressSet(_crowdsaleAddress);
    }

    /**
      * @dev Extend parent behavior requiring transfer to be out of lock-up period
      * @param _from address The address which you want to send tokens from
      * @param _to address The address which you want to transfer to
      * @param _value uint256 the amount of tokens to be transferred
      */
    function transferFrom(address _from, address _to, uint256 _value) public unlocked returns(bool) {
        super.transferFrom(_from, _to, _value);
    }

    /**
      * @dev Extend parent behavior requiring transfer to be out of lock-up period
      * @param _to address The address which you want to transfer to
      * @param _value uint256 the amount of tokens to be transferred
      */
    function transfer(address _to, uint256 _value) public unlocked returns(bool) {
        super.transfer(_to, _value);
    }

    /**
      * @dev Gives the crowdsaleAddress the token is bound to
      * @return The current crowdsaleAddress
      */
    function getCrowdsaleAddress() public view returns(address) {
        return crowdsaleAddress;
    }
}
