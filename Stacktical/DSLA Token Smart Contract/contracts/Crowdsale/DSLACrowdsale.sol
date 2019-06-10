pragma solidity 0.4.24;

import "../DSLA/DSLA.sol";
import "./PullPayment.sol";
import "./VestedCrowdsale.sol";
import "./Whitelist.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";


/**
  * @title DSLACrowdsale
  * @dev Crowdsale is a base contract for managing a token crowdsale,
  * allowing investors to purchase tokens with ether
  */
contract DSLACrowdsale is VestedCrowdsale, Whitelist, Pausable, PullPayment {
    // struct to store ico rounds details
    struct IcoRound {
        uint256 rate;
        uint256 individualFloor;
        uint256 individualCap;
        uint256 softCap;
        uint256 hardCap;
    }

    // mapping ico rounds
    mapping (uint256 => IcoRound) public icoRounds;
    // The token being sold
    DSLA private _token;
    // Address where funds are collected
    address private _wallet;
    // Amount of wei raised
    uint256 private totalContributionAmount;
    // Tokens to sell = 5 Billions * 10^18 = 5 * 10^27 = 5000000000000000000000000000
    uint256 public constant TOKENSFORSALE = 5000000000000000000000000000;
    // Current ico round
    uint256 public currentIcoRound;
    // Distributed Tokens
    uint256 public distributedTokens;
    // Amount of wei raised from other currencies
    uint256 public weiRaisedFromOtherCurrencies;
    // Refund period on
    bool public isRefunding = false;
    // Finalized crowdsale off
    bool public isFinalized = false;
    // Refunding deadline
    uint256 public refundDeadline;

    /**
      * Event for token purchase logging
      * @param purchaser who paid for the tokens
      * @param beneficiary who got the tokens
      * @param value weis paid for purchase
      * @param amount amount of tokens purchased
      */
    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    /**
      * @param wallet Address where collected funds will be forwarded to
      * @param token Address of the token being sold
      */
    constructor(address wallet, DSLA token) public {
        require(wallet != address(0) && token != address(0));

        icoRounds[1] = IcoRound(
            416700,
            3 ether,
            120 ether,
            0,
            1200 ether
        );

        icoRounds[2] = IcoRound(
            312500,
            12 ether,
            360 ether,
            0,
            6000 ether
        );

        icoRounds[3] = IcoRound(
            250000,
            3 ether,
            30 ether,
            7200 ether,
            17200 ether
        );

        _wallet = wallet;
        _token = token;
    }

    /**
      * @dev fallback function ***DO NOT OVERRIDE***
      */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
      * @dev low level token purchase ***DO NOT OVERRIDE***
      * @param _contributor Address performing the token purchase
      */
    function buyTokens(address _contributor) public payable {
        require(whitelist[_contributor]);

        uint256 contributionAmount = msg.value;

        _preValidatePurchase(_contributor, contributionAmount, currentIcoRound);

        totalContributionAmount = totalContributionAmount.add(contributionAmount);

        uint tokenAmount = _handlePurchase(contributionAmount, currentIcoRound, _contributor);

        emit TokensPurchased(msg.sender, _contributor, contributionAmount, tokenAmount);

        _forwardFunds();
    }

    /**
      * @dev Function to go to the next round
      * @return True bool when round is incremented
      */
    function goToNextRound() public onlyOwner returns(bool) {
        require(currentIcoRound >= 0 && currentIcoRound < 3);

        currentIcoRound = currentIcoRound + 1;

        return true;
    }

    /**
      * @dev Manually adds a contributor's contribution for private presale period
      * @param _contributor The address of the contributor
      * @param _contributionAmount Amount of wei contributed
      */
    function addPrivateSaleContributors(address _contributor, uint256 _contributionAmount)
    public onlyOwner
    {
        uint privateSaleRound = 1;
        _preValidatePurchase(_contributor, _contributionAmount, privateSaleRound);

        totalContributionAmount = totalContributionAmount.add(_contributionAmount);

        addToWhitelist(_contributor);

        _handlePurchase(_contributionAmount, privateSaleRound, _contributor);
    }

    /**
      * @dev Manually adds a contributor's contribution with other currencies
      * @param _contributor The address of the contributor
      * @param _contributionAmount Amount of wei contributed
      * @param _round contribution round
      */
    function addOtherCurrencyContributors(address _contributor, uint256 _contributionAmount, uint256 _round)
    public onlyOwner
    {
        _preValidatePurchase(_contributor, _contributionAmount, _round);

        weiRaisedFromOtherCurrencies = weiRaisedFromOtherCurrencies.add(_contributionAmount);

        addToWhitelist(_contributor);

        _handlePurchase(_contributionAmount, _round, _contributor);
    }

    /**
      * @dev Function to close refunding period
      * @return True bool
      */
    function closeRefunding() public returns(bool) {
        require(isRefunding);
        require(block.timestamp > refundDeadline);

        isRefunding = false;

        _withdrawFunds(wallet());

        return true;
    }

    /**
      * @dev Function to close the crowdsale
      * @return True bool
      */
    function closeCrowdsale() public onlyOwner returns(bool) {
        require(currentIcoRound > 0 && currentIcoRound < 4);

        currentIcoRound = 4;

        return true;
    }

    /**
      * @dev Function to finalize the crowdsale
      * @return True bool
      */
    function finalizeCrowdsale() public onlyOwner returns(bool) {
        require(currentIcoRound == 4 && !isRefunding);

        if (raisedFunds() < icoRounds[3].softCap) {
            isRefunding = true;
            refundDeadline = block.timestamp + 4 weeks;
        } else {
            require(!isFinalized);
            _withdrawFunds(wallet());
            _burnUnsoldTokens();
            isFinalized = true;
        }

        return  true;
    }

    /**
      * @dev Investors can claim refunds here if crowdsale is unsuccessful
      */
    function claimRefund() public {
        require(isRefunding);
        require(block.timestamp <= refundDeadline);
        require(payments(msg.sender) > 0);

        uint256 payment = _withdrawPayments(msg.sender);

        totalContributionAmount = totalContributionAmount.sub(payment);
    }

    /**
      * @dev Allows the sender to claim the tokens he is allowed to withdraw
      */
    function claimTokens() public {
        require(getWithdrawableAmount(msg.sender) != 0);

        uint256 amount = getWithdrawableAmount(msg.sender);
        withdrawn[msg.sender] = withdrawn[msg.sender].add(amount);

        _deliverTokens(msg.sender, amount);
    }

    /**
      * @dev returns the token being sold
      * @return the token being sold
      */
    function token() public view returns(DSLA) {
        return _token;
    }

    /**
      * @dev returns the wallet address that collects the funds
      * @return the address where funds are collected
      */
    function wallet() public view returns(address) {
        return _wallet;
    }

    /**
      * @dev Returns the total of raised funds
      * @return total amount of raised funds
      */
    function raisedFunds() public view returns(uint256) {
        return totalContributionAmount.add(weiRaisedFromOtherCurrencies);
    }

    // -----------------------------------------
    // Internal interface
    // -----------------------------------------
    /**
      * @dev Source of tokens. Override this method to modify the way in which
      * the crowdsale ultimately gets and sends its tokens.
      * @param _beneficiary Address performing the token purchase
      * @param _tokenAmount Number of tokens to be emitted
      */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount)
    internal
    {
        _token.transfer(_beneficiary, _tokenAmount);
    }

    /**
      * @dev Determines how ETH is stored/forwarded on purchases.
      */
    function _forwardFunds()
    internal
    {
        if (currentIcoRound == 2 || currentIcoRound == 3) {
            _asyncTransfer(msg.sender, msg.value);
        } else {
            _wallet.transfer(msg.value);
        }
    }

    /**
      * @dev Gets tokens allowed to deliver in the given round
      * @param _tokenAmount total amount of tokens involved in the purchase
      * @param _round Round in which the purchase is happening
      * @return Returns the amount of tokens allowed to deliver
      */
    function _getTokensToDeliver(uint _tokenAmount, uint _round)
    internal pure returns(uint)
    {
        require(_round > 0 && _round < 4);
        uint deliverPercentage = _round.mul(25);

        return _tokenAmount.mul(deliverPercentage).div(100);
    }

    /**
      * @dev Handles token purchasing
      * @param _contributor Address performing the token purchase
      * @param _contributionAmount Value in wei involved in the purchase
      * @param _round Round in which the purchase is happening
      * @return Returns the amount of tokens purchased
      */
    function _handlePurchase(uint _contributionAmount, uint _round, address _contributor)
    internal returns(uint) {
        uint256 soldTokens = distributedTokens.add(vestedTokens);
        uint256 tokenAmount = _getTokenAmount(_contributionAmount, _round);

        require(tokenAmount.add(soldTokens) <= TOKENSFORSALE);

        contributions[_contributor] = contributions[_contributor].add(_contributionAmount);
        contributionsRound[_contributor] = _round;

        uint tokensToDeliver = _getTokensToDeliver(tokenAmount, _round);
        uint tokensToVest = tokenAmount.sub(tokensToDeliver);

        distributedTokens = distributedTokens.add(tokensToDeliver);
        vestedTokens = vestedTokens.add(tokensToVest);

        _deliverTokens(_contributor, tokensToDeliver);

        return tokenAmount;
    }

    /**
      * @dev Validation of an incoming purchase.
      * @param _contributor Address performing the token purchase
      * @param _contributionAmount Value in wei involved in the purchase
      * @param _round Round in which the purchase is happening
      */
    function _preValidatePurchase(address _contributor, uint256 _contributionAmount, uint _round)
    internal view
    {
        require(_contributor != address(0));
        require(currentIcoRound > 0 && currentIcoRound < 4);
        require(_round > 0 && _round < 4);
        require(contributions[_contributor] == 0);
        require(_contributionAmount >= icoRounds[_round].individualFloor);
        require(_contributionAmount < icoRounds[_round].individualCap);
        require(_doesNotExceedHardCap(_contributionAmount, _round));
    }

    /**
      * @dev define the way in which ether is converted to tokens.
      * @param _contributionAmount Value in wei to be converted into tokens
      * @return Number of tokens that can be purchased with the specified _contributionAmount
      */
    function _getTokenAmount(uint256 _contributionAmount, uint256 _round)
    internal view returns(uint256)
    {
        uint256 _rate = icoRounds[_round].rate;
        return _contributionAmount.mul(_rate);
    }

    /**
      * @dev Checks if current round hardcap will not be exceeded by a new contribution
      * @param _contributionAmount purchase amount in Wei
      * @param _round Round in which the purchase is happening
      * @return true when current hardcap is not exceeded, false if exceeded
      */
    function _doesNotExceedHardCap(uint _contributionAmount, uint _round)
    internal view returns(bool)
    {
        uint roundHardCap = icoRounds[_round].hardCap;
        return totalContributionAmount.add(_contributionAmount) <= roundHardCap;
    }

    /**
      * @dev Function to burn unsold tokens
      */
    function _burnUnsoldTokens()
    internal
    {
        uint256 tokensToBurn = TOKENSFORSALE.sub(vestedTokens).sub(distributedTokens);

        _token.burn(tokensToBurn);
    }
}
