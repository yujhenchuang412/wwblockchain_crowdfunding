// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title CampaignFactory
 * @dev Store & retrieve Crowdfunding campaigns in a variable
 */

contract CampaignFactory {

    Campaign[] public deployedCampaigns;

    function createCampaign(uint minimumFund, uint threshold, string memory name, string memory description, string memory image, uint targetFund) public {
        Campaign newCampaign = new Campaign(minimumFund, threshold, name, description, image, targetFund);
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (Campaign[] memory) {
        return deployedCampaigns;
    }
    
}

contract Campaign {
    struct Contributor {
        bool hasFundBefore;
        bool isApprover;
        uint contribution;
    }

    struct Request {
        string description;
        uint requestFund;
        address recipient;
        bool isCompleted;
        uint approvalCount;
        address[] approversOfRequest;
    }

    uint public minimumPayment;
    uint public thresholdToBeApprover;
    address public campaignOwner;
    string public campaignName;
    string public campaignDescription;
    string public imageUrl;
    uint public targetAmount;
    bool public complete;
    uint public fundReceivedSoFar;
    mapping(address => Contributor) contributors;
    address[] public approvers;
    uint public contributorCount;
    uint public approverCount;
    mapping (uint => Request) requests;
    uint public requestCount;

    constructor(uint minimumFund, uint threshold, string memory name, string memory description, string memory image, uint targetFund) {
        minimumPayment = minimumFund;
        thresholdToBeApprover = threshold;
        campaignOwner = msg.sender;
        campaignName = name;
        campaignDescription = description;
        imageUrl = image;
        targetAmount = targetFund;
        complete = false;
        contributorCount = 0;
        approverCount = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == campaignOwner, "Oops! Action is only available to campaign's owner.");
        _;
    }

    modifier excludeOwner() {
         require(msg.sender != campaignOwner, "Oops! Campaign creators are not allowed to fund their own campaigns.");
         _;
    }

    function createRequest(string memory description, uint requestFund, address recipient) public onlyOwner {
        Request storage newRequest = requests[requestCount++];
        newRequest.description = description;
        newRequest.requestFund = requestFund;
        newRequest.recipient = recipient;
        newRequest.isCompleted = false;
        newRequest.approvalCount = 0;
    }

    function approveRequest(uint index) public excludeOwner{
        require(contributors[msg.sender].isApprover == true, "Sorry you are not eligible to approve the request.");

        uint numOfApprovers = requests[index].approversOfRequest.length;
        for (uint i = 0; i < numOfApprovers; ++i) {
            if (requests[index].approversOfRequest[i] == msg.sender) {
                return;
            }
        }

        requests[index].approversOfRequest.push(msg.sender);
        requests[index].approvalCount++;
    }

    function receiveFund() public payable excludeOwner {
        require(msg.value >= minimumPayment, "Oops! Funding doesn't meet the minimum contribution.");

        if ((contributors[msg.sender]).hasFundBefore == false) {
            contributors[msg.sender] = Contributor(true, false, msg.value);
            ++contributorCount;
        }
        else {
            contributors[msg.sender].contribution += msg.value;
        }

        if ((contributors[msg.sender].isApprover == false) && (msg.value >= thresholdToBeApprover)) {
            contributors[msg.sender].isApprover = true;
            ++approverCount;
        }

        fundReceivedSoFar += msg.value;
    }

    function showCurrentFund() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawTotalFund(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }
}