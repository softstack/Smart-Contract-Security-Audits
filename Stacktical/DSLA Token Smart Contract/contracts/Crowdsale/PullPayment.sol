pragma solidity 0.4.24;

import "./Escrow.sol";

/**
  * @title PullPayment (based on openzeppelin version with one function to withdraw funds to the wallet)
  * @dev Base contract supporting async send for pull payments. Inherit from this
  * contract and use asyncTransfer instead of send or transfer.
  */
contract PullPayment {
    Escrow private escrow;

    constructor() public {
        escrow = new Escrow();
    }

    /**
      * @dev Returns the credit owed to an address.
      * @param _dest The creditor's address.
      * @return Deposited amount by the address given as argument.
      */
    function payments(address _dest) public view returns(uint256) {
        return escrow.depositsOf(_dest);
    }

    /**
      * @dev Withdraw accumulated balance, called by payee.
      * @param _payee The address whose funds will be withdrawn and transferred to.
      * @return Amount withdrawn
      */
    function _withdrawPayments(address _payee) internal returns(uint256) {
        uint256 payment = escrow.withdraw(_payee);

        return payment;
    }

    /**
      * @dev Called by the payer to store the sent amount as credit to be pulled.
      * @param _dest The destination address of the funds.
      * @param _amount The amount to transfer.
      */
    function _asyncTransfer(address _dest, uint256 _amount) internal {
        escrow.deposit.value(_amount)(_dest);
    }

    /**
      * @dev Withdraws the wallet's funds.
      * @param _wallet address the funds will be transferred to.
      */
    function _withdrawFunds(address _wallet) internal {
        escrow.beneficiaryWithdraw(_wallet);
    }
}
