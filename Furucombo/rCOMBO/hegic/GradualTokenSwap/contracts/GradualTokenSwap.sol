pragma solidity 0.7.6;
// SPDX-License-Identifier: GPL-3.0-or-later
import "./ERC20Recovery.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @title GTS
 * @dev A token swap contract that gradually releases tokens on its balance
 */
contract GradualTokenSwap is ERC20Recovery {
    // solhint-disable not-rely-on-time
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Withdrawn(address account, uint256 amount);

    // Durations and timestamps in UNIX time, also in block.timestamp.
    uint256 public immutable start;
    uint256 public immutable duration;
    IERC20 public immutable rCOMBO;
    IERC20 public immutable COMBO;

    mapping(address => uint256) public released;
    mapping(address => uint256) public provided;

    /**
     * @dev Creates a contract that can be used for swapping rCOMBO into COMBO
     * @param _start UNIX time at which the unlock period starts
     * @param _duration Duration in seconds for unlocking tokens
     */
    constructor(
        uint256 _start,
        uint256 _duration,
        IERC20 _rCOMBO,
        IERC20 _COMBO
    ) {
        if (_start == 0) _start = block.timestamp;
        require(_duration > 0, "GTS: duration is 0");

        duration = _duration;
        start = _start;
        rCOMBO = _rCOMBO;
        COMBO = _COMBO;
    }

    /**
     * @dev Provide rCOMBO tokens to the contract for later exchange
     */
    function provide(uint256 amount) external {
        rCOMBO.safeTransferFrom(msg.sender, address(this), amount);
        provided[msg.sender] = provided[msg.sender].add(amount);
    }

    /**
     * @dev Withdraw unlocked user's COMBO tokens
     */
    function withdraw() external {
        uint256 amount = available(msg.sender);
        require(amount > 0, "GTS: You are have not unlocked tokens yet");
        released[msg.sender] = released[msg.sender].add(amount);
        COMBO.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev Calculates the amount of tokens that has already been unlocked but hasn't been swapped yet
     */
    function available(address account) public view returns (uint256) {
        return unlocked(account).sub(released[account]);
    }

    /**
     * @dev Calculates the total amount of tokens that has already been unlocked
     */
    function unlocked(address account) public view returns (uint256) {
        if (block.timestamp < start) return 0;
        if (block.timestamp >= start.add(duration)) {
            return provided[account];
        } else {
            return
                provided[account].mul(block.timestamp.sub(start)).div(duration);
        }
    }
}
