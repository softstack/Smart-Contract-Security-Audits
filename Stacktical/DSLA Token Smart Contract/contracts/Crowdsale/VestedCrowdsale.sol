pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";


/** @title VestedCrowdsale
  * @dev Extension of Crowdsale to allow a vested distribution of tokens
  * Users have to individually claim their tokens
  */
contract VestedCrowdsale {
    using SafeMath for uint256;

    mapping (address => uint256) public withdrawn;
    mapping (address => uint256) public contributions;
    mapping (address => uint256) public contributionsRound;
    uint256 public vestedTokens;

    /**
      * @dev Gives how much a user is allowed to withdraw at the current moment
      * @param _beneficiary The address of the user asking how much he's allowed
      * to withdraw
      * @return Amount _beneficiary is allowed to withdraw
      */
    function getWithdrawableAmount(address _beneficiary) public view returns(uint256) {
        uint256 step = _getVestingStep(_beneficiary);
        uint256 valueByStep = _getValueByStep(_beneficiary);
        uint256 result = step.mul(valueByStep).sub(withdrawn[_beneficiary]);

        return result;
    }

    /**
      * @dev Gives the step of the vesting (starts from 0 to steps)
      * @param _beneficiary The address of the user asking how much he's allowed
      * to withdraw
      * @return The vesting step for _beneficiary
      */
    function _getVestingStep(address _beneficiary) internal view returns(uint8) {
        require(contributions[_beneficiary] != 0);
        require(contributionsRound[_beneficiary] > 0 && contributionsRound[_beneficiary] < 4);

        uint256 march31 = 1554019200;
        uint256 april30 = 1556611200;
        uint256 may31 = 1559289600;
        uint256 june30 = 1561881600;
        uint256 july31 = 1564560000;
        uint256 sept30 = 1569830400;
        uint256 contributionRound = contributionsRound[_beneficiary];

        // vesting for private sale contributors
        if (contributionRound == 1) {
            if (block.timestamp < march31) {
                return 0;
            }
            if (block.timestamp < june30) {
                return 1;
            }
            if (block.timestamp < sept30) {
                return 2;
            }

            return 3;
        }
        // vesting for pre ico contributors
        if (contributionRound == 2) {
            if (block.timestamp < april30) {
                return 0;
            }
            if (block.timestamp < july31) {
                return 1;
            }

            return 2;
        }
        // vesting for ico contributors
        if (contributionRound == 3) {
            if (block.timestamp < may31) {
                return 0;
            }

            return 1;
        }
    }

    /**
      * @dev Gives the amount a user is allowed to withdraw by step
      * @param _beneficiary The address of the user asking how much he's allowed
      * to withdraw
      * @return How much a user is allowed to withdraw by step
      */
    function _getValueByStep(address _beneficiary) internal view returns(uint256) {
        require(contributions[_beneficiary] != 0);
        require(contributionsRound[_beneficiary] > 0 && contributionsRound[_beneficiary] < 4);

        uint256 contributionRound = contributionsRound[_beneficiary];
        uint256 amount;
        uint256 rate;

        if (contributionRound == 1) {
            rate = 416700;
            amount = contributions[_beneficiary].mul(rate).mul(25).div(100);
            return amount;
        } else if (contributionRound == 2) {
            rate = 312500;
            amount = contributions[_beneficiary].mul(rate).mul(25).div(100);
            return amount;
        }

        rate = 250000;
        amount = contributions[_beneficiary].mul(rate).mul(25).div(100);
        return amount;
    }
}
