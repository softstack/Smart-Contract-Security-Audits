pragma solidity 0.4.24;

import "./LockupToken.sol";

contract DSLA is LockupToken {
    string public name = "DSLA";
    string public symbol = "DSLA";
    uint8 public decimals = 18;
    // Tokenbits supply = 10 billions * 10^18 = 1 * 10^28 = 10000000000000000000000000000
    uint256 public constant INITIAL_SUPPLY = 10000000000000000000000000000;

    /**
      * @dev Constructor
      * @param _releaseDate The date from which users will be able to transfer
      * the token
      */
    constructor(uint256 _releaseDate) public LockupToken(_releaseDate) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}
