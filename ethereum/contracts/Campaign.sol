// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CampaignFactory {
    Campaign[] public campaigns;

    function createCampaign(uint256 minimum) public {
        Campaign newCampaign = new Campaign(minimum, msg.sender);
        campaigns.push(newCampaign);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        return campaigns;
    }
}

contract Campaign {
    struct Request {
        address payable recipient;
        string description;
        uint256 value;
        uint256 approvalCount;
        bool complete;
        mapping(address => bool) approvals;
    }

    address public manager;

    uint256 public minimumContribution;
    uint256 public approversCount;
    uint256 public requestsCount;
    uint256 requestIndex = 0;

    mapping(address => bool) public approvers;
    mapping(uint256 => Request) public requests;

    modifier restricted() {
        require(msg.sender == manager, "manager privileges only");
        _;
    }

    constructor(uint256 minimum, address creator) {
        manager = creator;
        minimumContribution = minimum;
    }

    function contribute() public payable {
        require(
            msg.value > minimumContribution,
            "minimum contribution required"
        );
        if (!approvers[msg.sender]) {
            approvers[msg.sender] = true;
            approversCount++;
        }
    }

    function createRequest(
        string memory description,
        uint256 value,
        address payable recipient
    ) public restricted {
        require(value <= address(this).balance);
        Request storage r = requests[requestIndex];

        r.description = description;
        r.recipient = recipient;
        r.value = value;
        r.complete = false;
        r.approvalCount = 0;

        requestIndex++;
        requestsCount++;
    }

    function approveRequest(uint256 index) public {
        Request storage r = requests[index];

        require(approvers[msg.sender]);
        require(!r.approvals[msg.sender]);

        r.approvals[msg.sender] = true;
        r.approvalCount++;
    }

    function finalizeRequest(uint256 index) public restricted {
        Request storage r = requests[index];

        require(r.approvalCount > (approversCount / 2));
        require(!r.complete);

        r.recipient.transfer(r.value);
        r.complete = true;
    }

    function getCampaignDetails()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        return (
            minimumContribution,
            address(this).balance,
            requestsCount,
            approversCount,
            manager
        );
    }

    function getRequestsCount() public view returns (uint256) {
        return requestsCount;
    }
}
