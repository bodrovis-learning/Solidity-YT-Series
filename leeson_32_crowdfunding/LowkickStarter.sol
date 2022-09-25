//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LowkickStarter {
    struct LowkickCampaign {
        Campaign targetContract;
        bool claimed;
    }
    mapping(uint => LowkickCampaign) public campaigns;
    uint private currentCampaign;
    address owner;
    uint constant MAX_DURATION = 30 days;

    event CampaignStarted(uint id, uint endsAt, uint goal, address organizer);

    function start(uint _goal, uint _endsAt) external {
        require(_goal > 0);
        require(
            _endsAt <= block.timestamp + MAX_DURATION &&
            _endsAt > block.timestamp
        );

        currentCampaign = currentCampaign + 1;

        Campaign newCampaign = new Campaign(_endsAt, _goal, msg.sender, currentCampaign);

        campaigns[currentCampaign] = LowkickCampaign({
            targetContract: newCampaign,
            claimed: false
        });

        emit CampaignStarted(currentCampaign, _endsAt, _goal, msg.sender);
    }

    function onClaimed(uint id) external {
        LowkickCampaign storage targetCampaign = campaigns[id];

        require(msg.sender == address(targetCampaign.targetContract));

        targetCampaign.claimed = true;
    }
}

contract Campaign {
    uint public endsAt;
    uint public goal;
    uint public pledged;
    uint public id;
    address public organizer;
    LowkickStarter parent;
    bool claimed;
    mapping(address => uint) pledges;

    event Pledged(uint amount, address pledger);

    constructor(uint _endsAt, uint _goal, address _organizer, uint _id) {
        endsAt = _endsAt;
        goal = _goal;
        organizer = _organizer;
        parent = LowkickStarter(msg.sender);
        id = _id;
    }

    function pledge() external payable {
        require(block.timestamp <= endsAt);
        require(msg.value > 0);

        pledged += msg.value;
        pledges[msg.sender] += msg.value;

        emit Pledged(msg.value, msg.sender);
    }

    function refundPledge(uint _amount) external {
        require(block.timestamp <= endsAt);

        pledges[msg.sender] -= _amount;
        pledged -= _amount;
    }

    function claim() external {
        require(block.timestamp > endsAt);
        require(msg.sender == organizer);
        require(pledged >= goal);
        require(!claimed);

        claimed = true;
        payable(organizer).transfer(pledged);

        parent.onClaimed(id);
    }

    function fullRefund() external {
        require(block.timestamp > endsAt);
        require(pledged < goal);

        uint refundAmount = pledges[msg.sender];
        pledges[msg.sender] = 0;
        payable(msg.sender).transfer(refundAmount);
    }
}