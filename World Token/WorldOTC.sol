// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./WorldVesting.sol";

contract WorldOTC is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable WORLD;
    address public immutable VESTING_LOGIC;

    mapping(address => address[]) public vestings;
    mapping(address => bool) public whitelisted;
    bool public whitelistedOnly = false;

    uint256 public rate;
    uint256 public vestingCliffDuration = 7 days;
    uint256 public vestingDuration = 28 days;

    constructor(address _world, address _vestingLogic, uint256 _rate) {
        require(_world != address(0), "WorldOTC: world is a zero address");
        require(_vestingLogic != address(0), "WorldOTC: vestingLogic is a zero address");
        require(_rate != 0, "WorldOTC: rate is zero");
        WORLD = IERC20(_world);
        VESTING_LOGIC = _vestingLogic;
        rate = _rate;
    }

    function buy() payable public {
        require(!whitelistedOnly || whitelisted[msg.sender], "WorldOTC: caller is not whitelisted");
        require(msg.value >= 1, "WorldOTC: eth value is less than 1");
        require((msg.value % 1 ether) == 0, "WorldOTC: eth value is not a whole number");

        uint256 balance = WORLD.balanceOf(address(this));
        uint256 amount = msg.value.mul(1e18).div(rate);
        require(amount <= balance, "WorldOTC: world balance is insufficient");

        WorldVesting vesting = WorldVesting(Clones.clone(VESTING_LOGIC));
        vesting.initialize(
            address(WORLD),
            msg.sender,
            rate,
            amount,
            block.timestamp,
            vestingCliffDuration,
            vestingDuration
        );

        WORLD.safeTransfer(address(vesting), amount);
        vestings[msg.sender].push(address(vesting));
    }

    function getVestings(address _account, uint256 _start, uint256 _length) external view returns (address[] memory) {
        address[] memory filteredVestings = new address[](_length);
        address[] memory accountVestings = vestings[_account];

        for (uint256 i = _start; i < _length; i++) {
            if (i == accountVestings.length) {
                break;
            }
            filteredVestings[i] = accountVestings[i];
        }

        return filteredVestings;
    }

    function getAllVestings(address _account) external view returns (address[] memory) {
        return vestings[_account];
    }

    function getVestingsLength(address _account) external view returns (uint256) {
        return vestings[_account].length;
    }

    function setRate(uint256 _rate) external onlyOwner {
        require(_rate != 0, "WorldOTC: rate is zero");
        rate = _rate;
    }

    function setVestingCliffDuration(uint256 _vestingCliffDuration) external onlyOwner {
        require(_vestingCliffDuration != 0, "WorldOTC: vestingCliffDuration is zero");
        require(_vestingCliffDuration <= vestingDuration, "WorldOTC: vestingCliffDuration is longer than vestingDuration");
        vestingCliffDuration = _vestingCliffDuration;
    }

    function setVestingDuration(uint256 _vestingDuration) external onlyOwner {
        require(_vestingDuration != 0, "WorldOTC: vestingDuration is zero");
        vestingDuration = _vestingDuration;
    }

    function setWhitelistedOnly(bool _whitelistedOnly) external onlyOwner {
        whitelistedOnly = _whitelistedOnly;
    }

    function addToWhitelist(address _account) external onlyOwner {
        require(_account != address(0), "WorldOTC: account is a zero address");
        whitelisted[_account] = true;
    }

    function removeFromWhitelist(address _account) external onlyOwner {
        require(_account != address(0), "WorldOTC: account is a zero address");
        whitelisted[_account] = false;
    }

    function withdrawTokens() public onlyOwner {
        uint256 worldBalance = WORLD.balanceOf(address(this));
        require(worldBalance != 0, "WorldOTC: no world tokens to withdraw");
        WORLD.safeTransfer(owner(), worldBalance);
    }

    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance != 0, "WorldOTC: no funds to withdraw");
        payable(owner()).transfer(balance);
    }

    receive() external payable {
        buy();
    }
}