// SPDX-License-Identifier:MIT
pragma solidity ^0.8.21;
contract Campaign {
    struct Request {
        string purpose;
        uint value;
        address payable reciver;
        bool status;
        uint approvalcount;
    }

    address public  manger;
    uint public  mincontri;

    Request[] public requests;
    mapping (address => bool) public approvers;
    mapping (uint => mapping (address => bool)) public approvals;
    uint public  approvalcount;

    modifier Resticted() {
        require(msg.sender == manger);
        _;
    }

    constructor(uint Mincontri) {
        manger = msg.sender;
        mincontri = Mincontri;
    }

    function Contribution() public payable {
        require(msg.value > mincontri);
        approvers[msg.sender] = true;
    }

    function createrequest(string memory purpose, uint value, address payable reciver) public Resticted {
        Request memory newrequest = Request({
            purpose: purpose,
            value: value,
            reciver: reciver,
            status: false,
            approvalcount: 0
        });
        requests.push(newrequest);
    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];
        require(approvers[msg.sender] == true);
        require(!approvals[index][msg.sender]);
        approvals[index][msg.sender] = true;
        request.approvalcount++;
    }

     function FinalizPay(uint index)public  Resticted{
        Request storage request = requests[index];
        require(request.approvalcount > (approvalcount/2));
        require(!request.status);
        request.reciver.transfer(request.value);
        request.status = true;
     }
}