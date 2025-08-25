// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CryloLotto {
    struct Ticket {
        address player;
        uint8[5] numbers;
        bool claimed;
    }

    address public owner;
    uint256 public drawId = 1;
    mapping(uint256 => Ticket[]) public tickets; // drawId => tickets
    mapping(uint256 => uint8[5]) public drawNumbers; // drawId => numbers
    mapping(uint256 => uint256) public prizePool; // drawId => total prize pool
    mapping(uint256 => bool) public prizesDistributed; // drawId => distributed

    // Prize pool split: 50/25/15/10
    uint256 public constant WIN5_BP = 5000;
    uint256 public constant WIN4_BP = 2500;
    uint256 public constant WIN3_BP = 1500;
    uint256 public constant ROLLOVER_BP = 1000;
    uint256 public constant DENOM = 10000;

    event TicketBought(address indexed player, uint8[5] numbers, uint256 drawId);
    event DrawPerformed(uint256 drawId, uint8[5] numbers, uint256 prizePool);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // 1. Player buys a ticket by sending BNB (can change to CRYLO for token use)
    function buyTicket(uint8[5] memory numbers) public payable {
        require(msg.value == 0.01 ether, "Ticket price: 0.01 BNB");
        tickets[drawId].push(Ticket(msg.sender, numbers, false));
        prizePool[drawId] += msg.value;
        emit TicketBought(msg.sender, numbers, drawId);
    }

    // 2. Owner draws the result (can upgrade to VRF/randomness later)
    function performDraw(uint8[5] memory numbers) public onlyOwner {
        require(drawNumbers[drawId][0] == 0, "Draw already performed");
        drawNumbers[drawId] = numbers;
        emit DrawPerformed(drawId, numbers, prizePool[drawId]);
    }

    // 3. Distribute prizes
    function distributePrizes() public onlyOwner {
        require(!prizesDistributed[drawId], "Already distributed");
        uint8[5] memory winningNumbers = drawNumbers[drawId];
        require(winningNumbers[0] != 0, "Draw not yet performed");

        // Arrays to track winners
        address[] memory win5;
        address[] memory win4;
        address[] memory win3;

        uint256 numTickets = tickets[drawId].length;
        for (uint256 i = 0; i < numTickets; i++) {
            uint8 matches = countMatches(tickets[drawId][i].numbers, winningNumbers);
            if (matches == 5) {
                win5 = append(win5, tickets[drawId][i].player);
            } else if (matches == 4) {
                win4 = append(win4, tickets[drawId][i].player);
            } else if (matches == 3) {
                win3 = append(win3, tickets[drawId][i].player);
            }
        }

        uint256 pool = prizePool[drawId];
        uint256 win5Prize = (pool * WIN5_BP) / DENOM;
        uint256 win4Prize = (pool * WIN4_BP) / DENOM;
        uint256 win3Prize = (pool * WIN3_BP) / DENOM;
        uint256 rollover = (pool * ROLLOVER_BP) / DENOM;

        // Pay winners equally
        if (win5.length > 0) {
            uint256 each = win5Prize / win5.length;
            for (uint256 i = 0; i < win5.length; i++) {
                payable(win5[i]).transfer(each);
            }
        } else {
            rollover += win5Prize;
        }

        if (win4.length > 0) {
            uint256 each = win4Prize / win4.length;
            for (uint256 i = 0; i < win4.length; i++) {
                payable(win4[i]).transfer(each);
            }
        } else {
            rollover += win4Prize;
        }

        if (win3.length > 0) {
            uint256 each = win3Prize / win3.length;
            for (uint256 i = 0; i < win3.length; i++) {
                payable(win3[i]).transfer(each);
            }
        } else {
            rollover += win3Prize;
        }

        // Save/forward rollover for next week
        prizePool[drawId + 1] += rollover;

        prizesDistributed[drawId] = true;
        drawId += 1; // Start next round
    }

    // Helper: counts matches
    function countMatches(uint8[5] memory a, uint8[5] memory b) internal pure returns (uint8) {
        uint8 matches = 0;
        for (uint8 i = 0; i < 5; i++) {
            for (uint8 j = 0; j < 5; j++) {
                if (a[i] == b[j]) {
                    matches++;
                    break;
                }
            }
        }
        return matches;
    }

    // Helper: append address to array (inefficient but simple for demo)
    function append(address[] memory arr, address a) internal pure returns (address[] memory) {
        address[] memory newArr = new address[](arr.length + 1);
        for (uint256 i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = a;
        return newArr;
    }
}

