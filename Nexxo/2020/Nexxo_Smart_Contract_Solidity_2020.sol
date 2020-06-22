pragma solidity ^0.4.26;


library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

library SafeMath {

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library Roles {
     struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


interface IERC20Vestable {
    function getIntrinsicVestingSchedule(address grantHolder)
    external
    view
    returns (
        uint32 cliffDuration,
        uint32 vestDuration,
        uint32 vestIntervalHours
    );

    function grantVestingTokens(
        address beneficiary,
        uint256 totalAmount,
        uint256 vestingAmount,
        uint32 startHour,
        uint32 duration,
        uint32 cliffDuration,
        uint32 interval,
        bool isRevocable
    ) external returns (bool ok);

    function currentTime() external view returns (uint32 hourNumber);

    function vestingForAccountAsOf(
        address grantHolder,
        uint32 onHourOrNow
    )
    external
    view
    returns (
        uint256 amountVested,
        uint256 amountNotVested,
        uint256 amountOfGrant,
        uint32 vestStartHour,
        uint32 cliffDuration,
        uint32 vestDuration,
        uint32 vestIntervalHours,
        bool isActive,
        bool wasRevoked
    );

    function vestingAsOf(uint32 onHourOrNow) external view returns (
        uint256 amountVested,
        uint256 amountNotVested,
        uint256 amountOfGrant,
        uint32 vestStartHour,
        uint32 cliffDuration,
        uint32 vestDuration,
        uint32 vestIntervalHours,
        bool isActive,
        bool wasRevoked
    );

    function revokeGrant(address grantHolder, uint32 onHour) external returns (bool);


    event VestingScheduleCreated(
        address indexed vestingWalletAddress,
        uint32 cliffDuration, uint32 indexed duration, uint32 interval,
        bool indexed isRevocable);

    event VestingTokensGranted(
        address indexed beneficiary,
        uint256 indexed vestingAmount,
        uint32 startHour,
        address vestingWalletAddress,
        address indexed grantor);

    event GrantRevoked(address indexed grantHolder, uint32 indexed onHour);
}

contract GrantorRole {
    using Roles for Roles.Role;

    event GrantorAdded(address indexed account);
    event GrantorRemoved(address indexed account);

    Roles.Role private _grantors;

    constructor () internal {
        _addGrantor(msg.sender);
    }

    modifier onlyGrantor() {
        require(isGrantor(msg.sender), "onlyGrantor: caller does not have the Grantor role");
        _;
    }

    modifier onlyGrantorOrSelf(address account) {
        require(isGrantor(msg.sender) || msg.sender == account, "onlyGrantorOrSelf: caller does not have the Grantor role");
        _;
    }

    function isGrantor(address account) public view returns (bool) {
        return _grantors.has(account);
    }

    function addGrantor(address account) public onlyGrantor {
        _addGrantor(account);
    }

    function removeGrantor(address account) public onlyGrantor {
        _removeGrantor(account);
    }

    function _addGrantor(address account) private {
        require(account != address(0));
        _grantors.add(account);
        emit GrantorAdded(account);
    }

    function _removeGrantor(address account) private {
        require(account != address(0));
        _grantors.remove(account);
        emit GrantorRemoved(account);
    }

    /**
     * @dev Applicable while transferOwnership and Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function applyGrantor(address newOwner) public onlyGrantor {
        _removeGrantor(msg.sender);
        _addGrantor(newOwner);
    }

}


contract VerifiedAccount {

    mapping(address => bool) private _isRegistered;

    constructor () internal {
        // The smart contract starts off registering itself, since address is known.
        registerAccount();
    }

    event AccountRegistered(address indexed account);

    /**
     * This registers the calling wallet address as a known address. Operations that transfer responsibility
     * may require the target account to be a registered account, to protect the system from getting into a
     * state where administration or a large amount of funds can become forever inaccessible.
     */
    function registerAccount() public returns (bool ok) {
        _isRegistered[msg.sender] = true;
        emit AccountRegistered(msg.sender);
        return true;
    }

    function isRegistered(address account) public view returns (bool ok) {
        return _isRegistered[account];
    }

    function _accountExists(address account) internal view returns (bool exists) {
        return account == msg.sender || _isRegistered[account];
    }

    modifier onlyExistingAccount(address account) {
        require(_accountExists(account), "account not registered");
        _;
    }

}

interface IERC20 {

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */

contract Pausable is PauserRole {

    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */

contract ERC20 is IERC20 {

    using SafeMath for uint256;

    uint private INITIAL_SUPPLY;
	uint private _totalSupply;
	mapping(address => uint) _balances;

    uint256 private _unitsOneEthCanBuy;
    uint256 private _totalEthInWei;
    address payable  _ownerWallet;

    mapping(address => mapping(address => uint)) _allowed;

    constructor(uint initalCapacity, uint256 unitsOneEthCanBuy, address payable ownerWallet) public {
        INITIAL_SUPPLY = initalCapacity;

        _totalSupply = initalCapacity;
        _balances[msg.sender] = initalCapacity;

        _unitsOneEthCanBuy = unitsOneEthCanBuy;
        _ownerWallet = ownerWallet;
    }

    function initalCapacity() public view returns (uint) {
		return INITIAL_SUPPLY;
	}

    function addBalance(address account, uint256 amount) internal returns (bool) {
         _balances[account] = _balances[account].add(amount);
        return true;
    }

    function subtractBalance(address account, uint256 amount) internal returns (bool) {
        _balances[account] = _balances[account].sub(amount);
        return true;
    }

	function unitsOneEthCanBuy() public view returns (uint256) {
		return _unitsOneEthCanBuy;
	}

	function totalEthInWei() public view returns (uint256) {
		return _totalEthInWei;
	}

	function updateTotalEthInWei(uint256 ethInWei) internal returns (bool) {
		_totalEthInWei = ethInWei;
		return true;
	}

    function ownerWallet() public view returns (address payable) {
		return _ownerWallet;
	}

    function allowed(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function setAllowedAmount(address owner, address spender, uint amount) internal returns (bool) {
         _allowed[owner][spender] = amount;
         return true;
    }

   /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint) {
        return _totalSupply - _balances[address(0)];
    }


   /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }


   /**
     * @dev See `IERC20.allowance`.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
       // _approve(sender, msg.sender, _allowed[sender][msg.sender].sub(amount));
       return true;
    }

   /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */

    function transfer(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
       return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer more than balance");
        require(amount > 0, "ERC20: transfer value negative");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }


    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

   /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

   /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(amount));
    }

    /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_balances[account] >= value, "ERC20: burn overflow from address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
    }

}

contract TokenVesting is VerifiedAccount, GrantorRole, IERC20Vestable, Ownable, ERC20 {

    using SafeMath for uint256;

	uint32 private constant THOUSAND_YEARS_HOURS = 8765832;
    /* See https://www.timeanddate.com/date/durationresult.html?m1=1&d1=1&y1=2000&m2=1&d2=1&y2=3000 */

    uint32 private constant TEN_YEARS_HOURS = THOUSAND_YEARS_HOURS / 100;
    /* Includes leap years (though it doesn't really matter) */

    uint32 private constant SECONDS_PER_HOUR = 60 * 60;
    /* 3600 seconds in a hour */

    uint32 private constant JAN_1_2000_SECONDS = 946684800;
    /* Saturday, January 1, 2000 0:00:00 (GMT) (see https://www.epochconverter.com/) */

    uint32 private constant JAN_1_2000_HOURS = JAN_1_2000_SECONDS / SECONDS_PER_HOUR;  /*  262968  */

    uint32 private constant JAN_1_3000_HOURS = JAN_1_2000_HOURS + THOUSAND_YEARS_HOURS; /*  9028800 */

    struct vestingSchedule {
        bool isValid;               /* true if an entry exists and is valid */
        bool isRevocable;           /* true if the vesting option is revocable (a gift), false if irrevocable (purchased) */
        uint32 cliffDuration;       /* Duration of the cliff, with respect to the grant start day, in hours. */
        uint32 duration;            /* Duration of the vesting schedule, with respect to the grant start day, in hours. */
        uint32 interval;            /* Duration in hours of the vesting interval. */
    }

    struct tokenGrant {
        bool isActive;                   /* true if this vesting entry is active and in-effect entry. */
        bool wasRevoked;                 /* true if this vesting schedule was revoked. */
        uint32 startHour;                 /* Start hour of the grant, in hours since the UNIX epoch (start of day). */
        uint256 totalAmount;             /* Total number of tokens to deposit into the account to vesting.*/
        uint256 vestingAmount;           /* Vesting token slot per interval.*/
        address vestingWalletAddress;    /* Address of wallet that is holding the vesting schedule. */
        address grantor;                 /* Grantor that made the grant */
    }

	mapping(address => vestingSchedule) private _vestingSchedules;
    mapping(address => tokenGrant) private _tokenGrants;

	 // =========================================================================
    // === Methods for administratively creating a vesting schedule for an account.
    // =========================================================================

    /**
     * @dev This one-time operation permanently establishes a vesting schedule in the given account.
     *
     * For standard grants, this establishes the vesting schedule in the beneficiary's account.
     * For uniform grants, this establishes the vesting schedule in the linked grantor's account.
     *
     * @param vestingWalletAddress = Account into which to store the vesting schedule. Can be the account
     *   of the beneficiary (for one-off grants) or the account of the grantor (for uniform grants
     *   made from grant pools).
     * @param cliffDuration = Duration of the cliff, with respect to the grant start day, in hours.
     * @param duration = Duration of the vesting schedule, with respect to the grant start day, in hours.
     * @param interval = Number of hours between vesting increases.
     * @param isRevocable = True if the grant can be revoked (i.e. was a gift) or false if it cannot
     *   be revoked (i.e. tokens were purchased).
     */
    function _setVestingSchedule(address vestingWalletAddress, uint32 cliffDuration, uint32 duration, uint32 interval,bool isRevocable)
      internal returns (bool ok) {

        // Check for a valid vesting schedule given (disallow absurd values to reject likely bad input).
        require(
            duration > 0 && duration <= TEN_YEARS_HOURS
            && cliffDuration < duration
            && interval >= 1,
            "invalid vesting schedule"
        );

        // Make sure the duration values are in harmony with interval (both should be an exact multiple of interval).
        require(duration % interval == 0 && cliffDuration % interval == 0,
            "invalid cliff/duration for interval"
        );

        // Create and populate a vesting schedule.
        _vestingSchedules[vestingWalletAddress] = vestingSchedule(
            true/*isValid*/,
            isRevocable,
            cliffDuration, duration, interval
        );

        // Emit the event and return success.
        emit VestingScheduleCreated(
            vestingWalletAddress,
            cliffDuration, duration, interval,
            isRevocable);
        return true;
    }

    function _hasVestingSchedule(address account) internal view returns (bool ok) {
        return _vestingSchedules[account].isValid;
    }

    /**
     * @dev returns all information about the vesting schedule directly associated with the given
     * account. This can be used to double check that a uniform grantor has been set up with a
     * correct vesting schedule. Also, recipients of standard (non-uniform) grants can use this.
     * This method is only callable by the account holder or a grantor, so this is mainly intended
     * for administrative use.
     *
     * Holders of uniform grants must use vestingAsOf() to view their vesting schedule, as it is
     * stored in the grantor account.
     *
     * @param grantHolder = The address to do this for the special value 0 to indicate today.
     * @return = A tuple with the following values:
     *   vestDuration = grant duration in hours.
     *   cliffDuration = duration of the cliff.
     *   vestIntervalHours = number of hours between vesting periods.
     */
    function getIntrinsicVestingSchedule(address grantHolder)
    public view onlyGrantorOrSelf(grantHolder) returns (
        uint32 vestDuration,
        uint32 cliffDuration,
        uint32 vestIntervalHours) {

        return (
        _vestingSchedules[grantHolder].duration,
        _vestingSchedules[grantHolder].cliffDuration,
        _vestingSchedules[grantHolder].interval
        );
    }


    // =========================================================================
    // === Token grants (general-purpose)
    // === Methods to be used for administratively creating one-off token grants with vesting schedules.
    // =========================================================================

    /**
     * @dev Immediately grants tokens to an account, referencing a vesting schedule which may be
     * stored in the same account (individual/one-off) or in a different account (shared/uniform).
     *
     * @param beneficiary = Address to which tokens will be granted.
     * @param totalAmount = Total number of tokens to deposit into the account.
     * @param vestingAmount = Out of totalAmount, the number of tokens subject to vesting.
     * @param startHour = Start hour of the grant's vesting schedule, in hours since the UNIX epoch
     *   (start of day). The startDay may be given as a date in the future or in the past, going as far
     *   back as year 2000.
     * @param vestingWalletAddress = Account where the vesting schedule is held (must already exist).
     * @param grantor = Account which performed the grant. Also the account from where the granted
     *   funds will be withdrawn.
     */
    function _grantVestingTokens(
        address beneficiary,
        uint256 totalAmount,
        uint256 vestingAmount,
        uint32 startHour,
        address vestingWalletAddress,
        address grantor
    )
    internal returns (bool ok)
    {
        // Make sure no prior grant is in effect.
        require(!_tokenGrants[beneficiary].isActive, "grant already exists");

        // Check for valid vestingAmount
		require(vestingAmount <= totalAmount,"vesting must be less than total.");
		require(vestingAmount > 0,"invalid vesting amount.");
		require(startHour > JAN_1_2000_HOURS,"invalid startTime for vesting.");
		require(startHour < JAN_1_3000_HOURS,"invalid startTime for vesting.");

        // Make sure the vesting schedule we are about to use is valid.
        require(_hasVestingSchedule(vestingWalletAddress), "no such vesting schedule");

        // Transfer the total number of tokens from grantor into the account's holdings.
        transfer(grantor, beneficiary, totalAmount);
        /* Emits a Transfer event. */

        // Create and populate a token grant, referencing vesting schedule.
        _tokenGrants[beneficiary] = tokenGrant(
            true /*isActive*/,
            false /*wasRevoked*/,
            startHour,
            totalAmount,
            vestingAmount,
            vestingWalletAddress, /* The wallet address where the vesting schedule is kept. */
            grantor               /* The account that performed the grant */
        );

        // Emit the event and return success.
        emit VestingTokensGranted(beneficiary, vestingAmount, startHour, vestingWalletAddress, grantor);
        return true;
    }

    /**
     * @dev Immediately grants tokens to an address, including a portion that will vest over time
     * according to a set vesting schedule. The overall duration and cliff duration of the grant must
     * be an even multiple of the vesting interval.
     *
     * @param beneficiary = Address to which tokens will be granted.
     * @param totalAmount = Total number of tokens to deposit into the account.
     * @param vestingAmount = Out of totalAmount, the number of tokens subject to vesting.
     * @param startHour = Start hour of the grant's vesting schedule, in hours since the UNIX epoch
     *   (start of day). The startDay may be given as a date in the future or in the past, going as far
     *   back as year 2000.
     * @param duration = Duration of the vesting schedule, with respect to the grant start day, in hours.
     * @param cliffDuration = Duration of the cliff, with respect to the grant start day, in hours.
     * @param interval = Number of hours between vesting increases.
     * @param isRevocable = True if the grant can be revoked (i.e. was a gift) or false if it cannot
     *   be revoked (i.e. tokens were purchased).
     */
    function grantVestingTokens(
        address beneficiary,
        uint256 totalAmount,
        uint256 vestingAmount,
        uint32 startHour,
        uint32 duration,
        uint32 cliffDuration,
        uint32 interval,
        bool isRevocable
    ) public onlyGrantor returns (bool ok) {

        // Make sure no prior vesting schedule has been set.
        require(!_tokenGrants[beneficiary].isActive, "grant already exists");

        // The vesting schedule is unique to this wallet and so will be stored here,
        _setVestingSchedule(beneficiary, cliffDuration, duration, interval, isRevocable);

        // Issue grantor tokens to the beneficiary, using beneficiary's own vesting schedule.
        _grantVestingTokens(beneficiary, totalAmount, vestingAmount, startHour, beneficiary, msg.sender);

        return true;
    }

    /**
     * @dev This variant only grants tokens if the beneficiary account has previously self-registered.
     */
    function safeGrantVestingTokens(
        address beneficiary, uint256 totalAmount, uint256 vestingAmount,
        uint32 startHour, uint32 duration, uint32 cliffDuration, uint32 interval,
        bool isRevocable) public onlyGrantor onlyExistingAccount(beneficiary) returns (bool ok) {

        return grantVestingTokens(
            beneficiary, totalAmount, vestingAmount,
            startHour, duration, cliffDuration, interval,
            isRevocable);
    }


    // =========================================================================
    // === Check vesting.
    // =========================================================================

    /**
     * @dev returns the current time, in hours since the UNIX epoch.
     */
    function currentTime() public view returns (uint32 hourNumber) {
        return uint32(block.timestamp / SECONDS_PER_HOUR);
    }

    function _effectiveHours(uint32 onHourOrNow) internal view returns (uint32 hourNumber) {
        return onHourOrNow == 0 ? currentTime() : onHourOrNow;   /* #onHourOrNow = epochSeconds/SECONDS_PER_HOUR */
    }

   /**
     * @dev Determines the amount of tokens that have not vested in the given account i.e. beneficiary.
     *
     * The math is: not vested amount = vesting amount * (end hour - on hour)/(end hour - start hour)
     *
     * @param grantHolder = The account to check.
     * @param onHourOrNow = The hour to check for, in hours since the UNIX epoch. Can pass
     */
    function _getNotVestedAmount(address grantHolder, uint32 onHourOrNow) public view returns (uint256 amountNotVested) {
        tokenGrant storage grant = _tokenGrants[grantHolder];
        vestingSchedule storage vesting = _vestingSchedules[grant.vestingWalletAddress];
        uint32 onHour = _effectiveHours(onHourOrNow);

        // If there's no schedule, or before the vesting cliff, then the full amount is not vested.
        if (!grant.isActive || onHour < grant.startHour + vesting.cliffDuration)
        {
            // None are vested (all are not vested)..i.e. All 10 tokens
            return grant.totalAmount;
        }
        // If after end of vesting, then the not vested amount is zero (all are vested).
        else if (onHour >= grant.startHour + vesting.duration)
        {
            // All are vested (none are not vested).....i.e all vested tokens
            return uint256(0);
        }
        // Otherwise a fractional amount is vested.
        else
        {
            // Compute the exact number of hours vested.
            uint32 hoursVested = onHour - grant.startHour; //...in epoch seconds..
            // Adjust result rounding down to take into consideration the interval.
            uint32 effectiveHoursVested = (hoursVested / vesting.interval) * vesting.interval;

            // Compute the fraction vested from schedule using 224.32 fixed point math for date range ratio.
            // Note: This is safe in 256-bit math because max value of X billion tokens = X*10^27 wei, and
            // typical token amounts can fit into 90 bits. Scaling using a 32 bits value results in only 125
            // bits before reducing back to 90 bits by dividing. There is plenty of room left, even for token
            // amounts many orders of magnitude greater than mere billions.
            uint256 vested = (grant.totalAmount.div(vesting.duration)).mul(effectiveHoursVested);
            return grant.totalAmount.sub(vested);
        }
     }

    /**
     * @dev Computes the amount of funds in the given account i.e. beneficiary which are available for use as of
     * the given hour. If there's no vesting schedule then 0 tokens are considered to be vested and
     * this just returns the full account balance.
     *
     * The math is: available amount = total funds - notVestedAmount.
     *
     * @param grantHolder = The account to check.
     * @param onHourOrNow = The hour to check for, in hours since the UNIX epoch.
     */
    function _getAvailableAmount(address grantHolder, uint32 onHourOrNow) internal view returns (uint256 amountAvailable) {
        uint256 totalTokens = balanceOf(grantHolder);
        uint256 vested = totalTokens.sub(_getNotVestedAmount(grantHolder, onHourOrNow));
        return vested;
    }

    /**
     * @dev returns all information about the grant's vesting as of the given day
     * for the given account. Only callable by the account holder or a grantor, so
     * this is mainly intended for administrative use.
     *
     * @param grantHolder = The address to do this for.
     * @param onHourOrNow = The day to check for, in days since the UNIX epoch. Can pass
     *   the special value 0 to indicate today.
     * @return = A tuple with the following values:
     *   amountVested = the amount out of vestingAmount that is vested
     *   amountNotVested = the amount that is vested (equal to vestingAmount - vestedAmount)
     *   amountOfGrant = the amount of tokens subject to vesting.
     *   vestStartHour = starting hour of the grant (in hours since the UNIX epoch).
     *   vestDuration = grant duration in hours.
     *   cliffDuration = duration of the cliff.
     *   vestIntervalHours = number of hours between vesting periods.
     *   isActive = true if the vesting schedule is currently active.
     *   wasRevoked = true if the vesting schedule was revoked.
     */
    function vestingForAccountAsOf(
        address grantHolder,
        uint32 onHourOrNow
    )
    public
    view
    onlyGrantorOrSelf(grantHolder)
    returns (
        uint256 amountVested,
        uint256 amountNotVested,
        uint256 amountOfGrant,
        uint32 vestStartDay,
        uint32 vestDuration,
        uint32 cliffDuration,
        uint32 vestIntervalDays,
        bool isActive,
        bool wasRevoked
    )
    {
        tokenGrant storage grant = _tokenGrants[grantHolder];
        vestingSchedule storage vesting = _vestingSchedules[grant.vestingWalletAddress];
        uint256 notVestedAmount = _getNotVestedAmount(grantHolder, onHourOrNow);
        uint256 grantAmount = grant.totalAmount;

        return (
        grantAmount.sub(notVestedAmount),
        notVestedAmount,
        grantAmount,
        grant.startHour,
        vesting.duration,
        vesting.cliffDuration,
        vesting.interval,
        grant.isActive,
        grant.wasRevoked
        );
    }

    /**
     * @dev returns all information about the grant's vesting as of the given day
     * for the current account, to be called by the account holder.
     *
     * @param onHourOrNow = The day to check for, in hours since the UNIX epoch. Can pass
     *   the special value 0 to indicate now().
     * @return = A tuple with the following values:
     *   amountVested = the amount out of vestingAmount that is vested
     *   amountNotVested = the amount that is vested (equal to vestingAmount - vestedAmount)
     *   amountOfGrant = the amount of tokens subject to vesting.
     *   vestStartHour = starting hour of the grant (in hours since the UNIX epoch).
     *   cliffDuration = duration of the cliff.
     *   vestDuration = grant duration in days.
     *   vestIntervalHours = number of hours between vesting periods.
     *   isActive = true if the vesting schedule is currently active.
     *   wasRevoked = true if the vesting schedule was revoked.
     */
    function vestingAsOf(uint32 onHourOrNow) public view returns (
        uint256 amountVested,
        uint256 amountNotVested,
        uint256 amountOfGrant,
        uint32 vestStartHour,
        uint32 vestDuration,
        uint32 cliffDuration,
        uint32 vestIntervalHours,
        bool isActive,
        bool wasRevoked
    )
    {
        return vestingForAccountAsOf(msg.sender, onHourOrNow);
    }

    /**
     * @dev returns true if the account has sufficient funds available to cover the given amount,
     *   including consideration for vesting tokens.
     *
     * @param account = The account to check.
     * @param amount = The required amount of vested funds.
     * @param onHour = The day to check for, in days since the UNIX epoch.
     */
    function _fundsAreAvailableOn(address account, uint256 amount, uint32 onHour) internal view returns (bool ok) {
        return (amount <= _getAvailableAmount(account, onHour));
    }

    /**
     * @dev Modifier to make a function callable only when the amount is sufficiently vested right now.
     *
     * @param account = The account to check.
     * @param amount = The required amount of vested funds.
     */
    modifier onlyIfFundsAvailableNow(address account, uint256 amount) {
        // Distinguish insufficient overall balance from insufficient vested funds balance in failure msg.
        require(_fundsAreAvailableOn(account, amount, currentTime()),
            balanceOf(account) < amount ? "insufficient funds" : "insufficient vested funds");
        _;
    }


    // =========================================================================
    // === Grant revocation
    // =========================================================================

    /**
     * @dev If the account has a revocable grant, this forces the grant to end based on computing
     * the amount vested up to the given date. All tokens that would no longer vest are returned
     * to the account of the original grantor.
     *
     * @param grantHolder = Address to which tokens will be granted.
     * @param onHourOrNow = The hour upon which the vesting schedule will be effectively terminated,
     *   in days since the UNIX epoch (start of day).
     */
    function revokeGrant(address grantHolder, uint32 onHourOrNow) public onlyGrantor returns (bool ok) {
        tokenGrant storage grant = _tokenGrants[grantHolder];
        vestingSchedule storage vesting = _vestingSchedules[grant.vestingWalletAddress];
        uint256 notVestedAmount;

        // Make sure grantor can only revoke from own pool.
        require(msg.sender == owner() || msg.sender == grant.grantor, "not allowed");
        // Make sure a vesting schedule has previously been set.
        require(grant.isActive, "no active grant");
        // Make sure it's revocable.
        require(vesting.isRevocable, "irrevocable");
        // Fail on likely erroneous input.
        require(onHourOrNow <= grant.startHour + vesting.duration, "no effect");
        // Don"t let grantor revoke anf portion of vested amount.
        require(onHourOrNow >= currentTime(), "cannot revoke vested holdings");

        notVestedAmount = _getNotVestedAmount(grantHolder, onHourOrNow);

        // Use ERC20 _approve() to forcibly approve grantor to take back not-vested tokens from grantHolder.
        _approve(grantHolder, grant.grantor, notVestedAmount);
        /* Emits an Approval Event. */
        transferFrom(grantHolder, grant.grantor, notVestedAmount);
        /* Emits a Transfer and an Approval Event. */

        // Kill the grant by updating wasRevoked and isActive.
        _tokenGrants[grantHolder].wasRevoked = true;
        _tokenGrants[grantHolder].isActive = false;

        emit GrantRevoked(grantHolder, onHourOrNow);
        /* Emits the GrantRevoked event. */
        return true;
    }
}


contract Burnable {
  event Burn(address indexed burner, uint256 value);
}


contract NexxoTokens is Pausable, Ownable, Burnable, TokenVesting {
	string public name;
	string public symbol;
	uint8  public decimals;

    uint private INITIAL_SUPPLY = 100000000000000000000000000000;
    uint256 private UNIT_PER_ETH_BUY=294380;

   // Start : to block and unblock particular address.
        struct EntityStruct {
         address walletAddress;
         uint indexPointer; // the corresponding row number in the index
        }

        mapping (address => EntityStruct) blockedAddressStructs;
        address[] blockedAddressList; // unordered list of keys that actually exist
    // End : to block and unblock particular address.

	constructor() public ERC20(INITIAL_SUPPLY, UNIT_PER_ETH_BUY, msg.sender) {
        symbol = "NEXXO";
        name = "Nexxo Tokens";
        decimals = 18;
       emit Transfer(address(0), msg.sender, INITIAL_SUPPLY); // Broadcast a message to the blockchain
    }

    function () external payable whenNotPaused {
        require(!isBlocked(msg.sender), "msg.sender is blocked.");
        updateTotalEthInWei(totalEthInWei() + msg.value);
        uint256 amount = msg.value * unitsOneEthCanBuy();
        require(balanceOf(ownerWallet()) >= amount, "Custom-Token : amount more than balance");

        subtractBalance(ownerWallet(), amount);
        addBalance(msg.sender,amount);

        emit Transfer(ownerWallet(), msg.sender, amount); // Broadcast a message to the blockchain
        ownerWallet().transfer(msg.value);   //Transfer ether to fundsWallet
    }

    function totalSupply() public view returns (uint) {
        return super.totalSupply();
    }

    function balanceOf(address tokenOwner) public view returns (uint ownerBalance) {
        return super.balanceOf(tokenOwner);
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed(tokenOwner,spender);
    }

    function transferFrom(address from, address to, uint tokens) public whenNotPaused onlyIfFundsAvailableNow(from, tokens) returns (bool success)  {
        require(!isBlocked(from), "from-address is blocked.");
        require(!isBlocked(to), "to-address is blocked.");

        return super.transferFrom(from, to, tokens);
    }

    function transfer(address to, uint tokens) public whenNotPaused returns (bool success) {
        require(!isBlocked(to), "to-address is blocked.");
        require(!isBlocked(msg.sender), "msg.sender is blocked.");

        return super.transfer(msg.sender, to, tokens);
    }

    function approve(address spender, uint tokens) public onlyOwner returns (bool success) {
        setAllowedAmount(msg.sender, spender, tokens);
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function burn(uint256 amount) public onlyOwner{
        _burn(msg.sender, amount);
       emit Burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public onlyOwner{
        _burnFrom(account, amount);
    }

    function startVestingTokens(address beneficiary, uint256 totalAmount, uint256 vestingAmount, uint32 startDay, uint32 duration,
        						 uint32 cliffDuration, uint32 interval,bool isRevocable) public whenNotPaused onlyOwner {
      grantVestingTokens(beneficiary, totalAmount, vestingAmount, startDay, duration, cliffDuration, interval, isRevocable);
    }


    function fetchNotVestedAmount(address grantHolder, uint32 onHourOrNow) public onlyOwner view returns (uint256 amountNotVested) {
      return _getNotVestedAmount(grantHolder, onHourOrNow);
    }


    function fetchAvailableAmount(address grantHolder, uint32 onHourOrNow) public onlyOwner view returns (uint256 amountAvailable){
      return _getAvailableAmount(grantHolder, onHourOrNow);
    }

    function getIntrinsicVestingSchedule(address grantHolder) public onlyOwner view returns (uint32 vestDuration,
        uint32 cliffDuration,
        uint32 vestIntervalHours) {
     return getIntrinsicVestingSchedule(grantHolder);
   }

  // Start : to block and unblock particular address.

         function isBlocked(address walletAddress) internal view returns (bool isExists){
           if(blockedAddressList.length == 0) return false;
            return (blockedAddressList[blockedAddressStructs[walletAddress].indexPointer] == walletAddress);
         }

         function getBlockedAddressCount() public onlyOwner view returns(uint blockedWalletAddressCount) {
           return blockedAddressList.length;
         }

         function getBlockedAddressList() public onlyOwner view returns(address [] memory) {
           return blockedAddressList;
         }

       function blockWalletAddress(address walletAddress) public onlyOwner returns(bool success) {
         require(!isBlocked(walletAddress), "walletAddress is already blocked.");

         blockedAddressStructs[walletAddress].walletAddress = walletAddress;
         blockedAddressStructs[walletAddress].indexPointer = blockedAddressList.push(walletAddress) - 1;
         return true;
       }

      function unblockWalletAddress(address walletAddress) public onlyOwner returns(bool success) {
          require(isBlocked(walletAddress), "walletAddress is not blocked yet.");
          require((blockedAddressList.length != 0), "blockedAddressList is empty.");

         uint rowToDelete = blockedAddressStructs[walletAddress].indexPointer;
         address keyToMove   = blockedAddressList[blockedAddressList.length-1];
         blockedAddressList[rowToDelete] = keyToMove;

         blockedAddressStructs[keyToMove].indexPointer = rowToDelete;
         blockedAddressList.length--;
         return true;
       }

   // End : to block and unblock particular address.


 }
