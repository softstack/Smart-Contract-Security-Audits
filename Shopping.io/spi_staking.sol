// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

//Staking...
contract Staking is Ownable, Pausable, ReentrancyGuard {
	using SafeMath for uint256;

	struct UserInfo {
		uint256 amount; // current staked SPI
		uint256 createdAt; // unix timestamp when the user created
		uint256 lastUpdateAt; // unix timestamp for last details update (when pointsDebt calculated)
		uint256 pointsDebt; // total points collected before latest deposit
	}

	uint256 public minimumAmount = 1 * (10**18); //1 SPI
	uint256 public maxAmount = 1000 * (10**18); //1000 SPI
	uint256 public lockTime = 1 hours;

	//emissionRate - points generated per SPI token per second staked
	//10000000000 = 0.01 SPI per 1 SPI staked 11days
	//10000000000000 = 10 SPI per 1 SPI staked 11days [TEST]
	uint256 public emissionRate;

	IERC20 spiToken; // token being staked

	mapping(address => UserInfo) public userInfo;

	event StakeClaimed(address user, uint256 amount);
	event RewardAdded(uint256 amount);
	event EmissionRateChanged(uint256 newEmissionRate);

	constructor(IERC20 _lpToken, uint256 _emissionRate) {
		spiToken = _lpToken;
		emissionRate = _emissionRate;
	}

	// Add reward to the smart contract (must have approval)
	function addReward(uint256 _amount) external {
		spiToken.transferFrom(msg.sender, address(this), _amount);
		emit RewardAdded(_amount);
	}

	//the core of the contract (must have approval)
	function stake(uint256 _amount) external whenNotPaused nonReentrant {
		require(_amount >= minimumAmount, "amount below minimumAmount");
		require(_amount <= maxAmount, "amount greater than maxAmount");
		require(spiToken.transferFrom(msg.sender, address(this), _amount), "failed to transfer");

		// already deposited before
		UserInfo storage user = userInfo[msg.sender];
		if (user.amount != 0) {
			user.pointsDebt = pointsBalance(msg.sender);
		}

		user.amount = user.amount.add(_amount);
		user.lastUpdateAt = block.timestamp;
		user.createdAt = block.timestamp;
	}

	//get them rewards
	function claim() public nonReentrant {
		UserInfo storage user = userInfo[msg.sender];

		// deduct points
		uint256 amountToTransfer = pointsBalance(msg.sender);
		user.pointsDebt = 0;
		user.lastUpdateAt = block.timestamp;

		spiToken.transfer(msg.sender, amountToTransfer);
	}

	function unstake() external {
		UserInfo storage user = userInfo[msg.sender];
		require(user.amount >= 0, "insufficient staked");
		require(user.createdAt + lockTime <= block.timestamp, "tokens are locked");

		// First, send all unclaimed rewards
		claim();

		uint256 userAmount = user.amount;
		user.amount = 0;

		spiToken.transfer(msg.sender, userAmount);
	}

	//calculates the undebitted points. (seconds since staked) X emission rate X amount / 10^18
	function _unDebitedPoints(UserInfo memory user) internal view returns (uint256) {
		return block.timestamp.sub(user.lastUpdateAt).mul(emissionRate).mul(user.amount).div(1e18);
	}

	//calculte how many points an address has
	function pointsBalance(address userAddress) public view returns (uint256) {
		UserInfo memory user = userInfo[userAddress];
		return user.pointsDebt.add(_unDebitedPoints(user));
	}

	//change how many SPI per second you gain (in wei)
	function changeEmissionRate(uint256 newEmissionRate) public onlyOwner {
		emissionRate = newEmissionRate;
		emit EmissionRateChanged(newEmissionRate);
	}

	//owner can withdraw any token sent here
	function reclaimToken(IERC20 token, uint256 _amount) public onlyOwner {
		require(address(token) != address(0), "no 0 address");
		require(address(token) != address(spiToken), "can't withdraw the reward");
		uint256 balance = token.balanceOf(address(this));
		require(_amount <= balance, "you can't withdraw more than you have");
		token.transfer(msg.sender, _amount);
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	//owner can withdraw any ETH sent here
	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}
}