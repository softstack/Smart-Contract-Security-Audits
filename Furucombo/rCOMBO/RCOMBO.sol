pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./hegic/GradualTokenSwap/contracts/GradualTokenSwap.sol";

contract RCOMBO is ERC20, GradualTokenSwap {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    constructor(uint256 _amount, uint256 _start)
        ERC20("Furucombo IOU COMBO Token", "rCOMBO")
        GradualTokenSwap(
            _start,
            360 days,
            IERC20(address(this)),
            IERC20(0xfFffFffF2ba8F66D4e51811C5190992176930278)
        )
    {
        uint256 supply = _amount * (10**uint256(decimals()));
        _mint(msg.sender, supply);
    }

    /**
     * @dev Provide RCOMBO tokens to the contract for later exchange
     * on `user`'s behalf.
     */
    function provideFor(address user, uint256 amount) external {
        _transfer(_msgSender(), address(this), amount);
        provided[user] = provided[user].add(amount);
    }

    /**
     * @dev Withdraw unlocked user's COMBO tokens on `user`'s behalf.
     */
    function withdrawFor(address user) external {
        uint256 amount = available(user);
        require(amount > 0, "GTS: You are have not unlocked tokens yet");
        released[user] = released[user].add(amount);
        COMBO.safeTransfer(user, amount);
        emit Withdrawn(user, amount);
    }
}
