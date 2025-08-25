// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

interface ICryloTicket {
    function totalTicketsSold() external view returns (uint256);
    function requestRandomWinner() external returns (uint256);
}

contract CryloDrawScheduler is Ownable, AutomationCompatibleInterface {
    ICryloTicket public ticket;
    uint256 public nextDrawTime;                // unix timestamp for next Saturday 20:00 UTC
    uint256 public constant INTERVAL = 7 days;  // weekly
    bool    public paused;

    event Scheduled(uint256 nextTime);
    event Performed(uint256 at);

    constructor(address _ticket, uint256 _firstDrawTime) {
        require(_ticket != address(0), "ticket=0");
        require(_firstDrawTime > block.timestamp, "start in future");
        ticket = ICryloTicket(_ticket);
        nextDrawTime = _firstDrawTime;
        emit Scheduled(_firstDrawTime);
    }

    function setNextDrawTime(uint256 t) external onlyOwner {
        require(t > block.timestamp, "future only");
        nextDrawTime = t;
        emit Scheduled(t);
    }

    function setPaused(bool p) external onlyOwner { paused = p; }

    // ---------- Chainlink Automation ----------
    function checkUpkeep(bytes calldata) external view override
        returns (bool upkeepNeeded, bytes memory /*performData*/)
    {
        upkeepNeeded = (!paused) &&
                       (block.timestamp >= nextDrawTime) &&
                       (ticket.totalTicketsSold() > 0);
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        require(!paused, "paused");
        require(block.timestamp >= nextDrawTime, "too-early");
        require(ticket.totalTicketsSold() > 0, "no tickets");

        ticket.requestRandomWinner();       // VRF request happens inside the ticket
        nextDrawTime += INTERVAL;           // schedule next Saturday
        emit Performed(block.timestamp);
    }
}
