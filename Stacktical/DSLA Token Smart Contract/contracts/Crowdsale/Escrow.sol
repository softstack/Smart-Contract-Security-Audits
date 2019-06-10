pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
  * @title Escrow (based on openzeppelin version with one function to withdraw funds to the wallet)
  * @dev Base escrow contract, holds funds destinated to a payee until they
  * withdraw them. The contract that uses the escrow as its payment method
  * should be its owner, and provide public methods redirecting to the escrow's
  * deposit and withdraw.
  */
contract Escrow is Ownable {
    using SafeMath for uint256;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private deposits;

    /**
      * @dev Stores the sent amount as credit to be withdrawn.
      * @param _payee The destination address of the funds.
      */
    function deposit(address _payee) public onlyOwner payable {
        uint256 amount = msg.value;
        deposits[_payee] = deposits[_payee].add(amount);

        emit Deposited(_payee, amount);
    }

    /**
      * @dev Withdraw accumulated balance for a payee.
      * @param _payee The address whose funds will be withdrawn and transferred to.
      * @return Amount withdrawn
      */
    function withdraw(address _payee) public onlyOwner returns(uint256) {
        uint256 payment = deposits[_payee];

        assert(address(this).balance >= payment);

        deposits[_payee] = 0;

        _payee.transfer(payment);

        emit Withdrawn(_payee, payment);
        return payment;
    }

    /**
      * @dev Withdraws the wallet's funds.
      * @param _wallet address the funds will be transferred to.
      */
    function beneficiaryWithdraw(address _wallet) public onlyOwner {
        uint256 _amount = address(this).balance;
        
        _wallet.transfer(_amount);

        emit Withdrawn(_wallet, _amount);
    }

    /**
      * @dev Returns the deposited amount of the given address.
      * @param _payee address of the payee of which to return the deposted amount.
      * @return Deposited amount by the address given as argument.
      */
    function depositsOf(address _payee) public view returns(uint256) {
        return deposits[_payee];
    }
}
