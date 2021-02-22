pragma solidity 0.7.4;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * This contract is based on open-zeppelin's TokenVesting.sol
 * (https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/drafts/TokenVesting.sol)
 *
 * @title WorldVesting
 * A world token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period.
 */
contract WorldVesting is Initializable {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // beneficiary of world tokens after they are released
    address public beneficiary;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 public cliff; // the cliff time of the world tokens vesting
    uint256 public start; // the start time of the token vesting
    uint256 public duration; // the duration of the world tokens vesting
    uint256 public released;  // the amount of the world tokens released
    uint256 public rate; // the eth rate per world token
    uint256 public amount; // the total amount of the world tokens vested

    IERC20 public world;

    /**
     * Initialize vesting contract that vests its balance of world tokens to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _rate eth rate per world token
     * @param _amount total amount of the world tokens vested
     * @param _cliffDuration duration in seconds of the cliff in which tokens will begin to vest
     * @param _start the time (as Unix time) at which point vesting starts
     * @param _duration duration in seconds of the period in which the tokens will vest
     */
    function initialize (
        address _world,
        address _beneficiary,
        uint256 _rate,
        uint256 _amount,
        uint256 _start,
        uint256 _cliffDuration,
        uint256 _duration
    ) public initializer {
        require(_world != address(0), "WorldVesting: world is a zero address");
        require(_beneficiary != address(0), "WorldVesting: beneficiary is a zero address");
        require(_rate > 0, "WorldVesting: rate is 0");
        require(_amount > 0, "WorldVesting: amount is 0");
        require(_cliffDuration <= _duration, "WorldVesting: cliff is longer than duration");
        require(_duration > 0, "WorldVesting: duration is 0");
        require(_start.add(_duration) > block.timestamp, "WorldVesting: final time is before current time");

        world = IERC20(_world);
        beneficiary = _beneficiary;
        rate = _rate;
        amount = _amount;
        duration = _duration;
        cliff = _start.add(_cliffDuration);
        start = _start;
    }

    /**
     * Transfers vested world tokens to beneficiary.
     */
    function release() external {
        uint256 unreleased = releasableAmount();

        require(unreleased > 0, "WorldVesting: no world tokens are due");

        released = released.add(unreleased);

        world.safeTransfer(beneficiary, unreleased);
    }

    /**
     * Calculates the amount that has already vested but hasn't been released yet.
     */
    function releasableAmount() public view returns (uint256) {
        return vestedAmount().sub(released);
    }

    /**
     * Calculates the amount that has already vested.
     */
    function vestedAmount() public view returns (uint256) {
        uint256 currentBalance = world.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(released);

        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start.add(duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(start)).div(duration);
        }
    }
}