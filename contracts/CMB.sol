// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CMB {
    struct Payment {
        address payable bo;
        address payable client;
        string data;
        uint256 fee;
        Status status;
    }

    /*
     * Status:
     * After BO creates payment: Initial,
     * After Client escrows money: Escrow,
     * After Client confirm to release money: Ready
     * After BO release money: Release
     * After Client withdraw money: Finish
    */
    enum Status { Initial, Escrow, Ready, Release, Finish }

    mapping(uint256 => Payment) public payments;

    event CreatePayment(uint256 indexed paymentId, address payable _bo, address payable _client, string data);
    event EscrowMoney(uint256 indexed paymentId);
    event ConfirmToRelease(uint256 indexed paymentId);
    event ReleaseMoney(uint256 indexed paymentId);
    event Withdraw(uint256 indexed paymentId);

    function createPayment(uint paymentId, address payable _client, string memory data) public payable {
        require(
            msg.sender != _client, 
            "Business Owner and Client can not be same"
        );
        address payable bo = payable(msg.sender);
        payments[paymentId] = Payment(bo, _client, data, msg.value, Status.Initial);
        emit CreatePayment(paymentId, bo, _client, data);
    }

    function escrowMoney(uint paymentId) public {
        Payment storage payment = payments[paymentId];
        require(
            msg.sender == payment.client 
            && payment.status == Status.Initial, 
            "Only Client can escrow money and payment need to created"
        );

        payment.status = Status.Escrow;
        emit EscrowMoney(paymentId);
    }

    function confirmToRelease(uint256 paymentId) public {
        Payment storage payment = payments[paymentId];
        require(
            msg.sender == payment.client 
            && payment.status == Status.Escrow, 
            "Only Client can confirm to release money and money must be escrowed"
        );

        payment.status = Status.Ready;
        emit ConfirmToRelease(paymentId);
    }

    function releaseMoney(uint256 paymentId) public {
        Payment storage payment = payments[paymentId];
        require(
            msg.sender == payment.bo 
            && payment.status == Status.Ready, 
            "Only Business Owner can release money and it must be confirmed by client"
        );

        payment.status = Status.Release;
        emit ReleaseMoney(paymentId);
    }

    function withdraw(uint256 paymentId) public payable {
        Payment storage payment = payments[paymentId];
        require(
            payment.client == msg.sender 
            && payment.status == Status.Release,
            "Only Client can withdraw money"
        );
        
        payable(msg.sender).transfer(payment.fee);
        payment.status = Status.Finish;
        emit Withdraw(paymentId);
    }

    function getBusinessOwner(uint256 paymentId) public view returns (address)  {
        Payment storage payment = payments[paymentId];
        return payment.bo;
    }

    function getBalanceContract() public view returns (uint256) {
        return address(this).balance;
    }

    function getFee(uint256 paymentId) public view returns (uint256) {
        Payment storage payment = payments[paymentId];
        return payment.fee;
    }

    modifier getPayment(uint256 paymentId) {
        Payment storage payment = payments[paymentId];
        _;
    }
}