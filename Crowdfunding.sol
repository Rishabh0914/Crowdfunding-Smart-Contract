//SPDX-License-Identifier: GPL - 3.0

pragma solidity >=0.5.0 <0.9.0;

contract CrowdFunding{
    address public manager;
    mapping(address=>uint) public contributors;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContibutors;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voted;
    }

    mapping(uint=>Request) public request;
    uint public numRequest;
    constructor(uint _target, uint _deadline){
        target = _target;
        deadline = block.timestamp+_deadline;
        minimumContribution = 100 wei;
        manager = msg.sender;
    }

    function sendEth() public payable{
        require(block.timestamp < deadline,"Deadline has passed");
        require(msg.value >= minimumContribution,"Donate more");

        if (contributors[msg.sender] == 0){
            noOfContibutors++;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function getContractBalance() public view returns(uint){
        require(msg.sender == manager);
        return address(this).balance;
    }

    function refund() public{
        require(block.timestamp > deadline && raisedAmount < target,"You're not eligible for refund");
        require(contributors[msg.sender] > 0,"You've never contributed");
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    modifier onlyManager(){
        require(msg.sender==manager,"Access Denied");
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newStorage = request[numRequest];
        numRequest++;
        newStorage.description = _description;
        newStorage.recipient = _recipient;
        newStorage.value = _value;
        newStorage.completed = false;
        newStorage.noOfVoters = 0;
    }

    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender] > 0,"First be a contributor");
        Request storage thisRequest = request[_requestNo];
        require(thisRequest.voted[msg.sender] == false,"You have voted before");
        thisRequest.voted[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmount>=target);
        Request storage thisRequest = request[_requestNo];
        require(thisRequest.completed=false,"The request has been completed");
        require(thisRequest.noOfVoters > noOfContibutors/2,"Majority does not suuport");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }

} 