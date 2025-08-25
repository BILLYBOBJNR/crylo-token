// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Import OpenZeppelin & Chainlink contracts
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract CryloLottoTicket is ERC721Enumerable, Ownable, VRFConsumerBaseV2 {
    IERC20 public immutable CRYLO_TOKEN;
    address public devWallet;
    address public prizeWallet;
    uint256 public nextTicketId = 1;
    uint256 public ticketPriceUsd = 2e18; // $2 in 18 decimals
    uint256 public minHoldUsd = 10e18; // $10 minimum CRYLO hold
    uint256 public totalTicketsSold;

    // ==============================
    // 🔮 Chainlink VRF Setup Section
    // ==============================
    VRFCoordinatorV2Interface coordinator;
    // TODO: Replace with actual Subscription ID from Chainlink dashboard
    uint64 public subscriptionId;
    // TODO: Replace with actual KeyHash from Chainlink docs for your network
    bytes32 public keyHash;
    // You may tweak these later
    uint32 public callbackGasLimit = 200000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;
    // Tracks the last randomness request
    uint256 public lastRequestId;
    uint256 public lastRandomWord;
    address public scheduler;

    // ==============================
    // 🔊 Events
    // ==============================
    event TicketMinted(address indexed to, uint256 ticketId, uint256 pricePaidUsd);
    event WinnerSelected(address winner, uint256 ticketId);

    // ==============================
    // Modifier for owner or scheduler
    // ==============================
    modifier onlyOwnerOrScheduler() {
        require(msg.sender == owner() || msg.sender == scheduler, "Caller is not the owner or scheduler");
        _;
    }

    constructor(
        address _cryloToken,
        address _devWallet,
        address _prizeWallet,
        // TODO: Replace with your actual Chainlink values before deploy
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash
    )
        ERC721("Crylo Lottery Ticket", "CRYLOTICKET")
        Ownable(msg.sender)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        CRYLO_TOKEN = IERC20(_cryloToken);
        devWallet = _devWallet;
        prizeWallet = _prizeWallet;
        // Assign Chainlink settings
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        coordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
    }

    // ======================================
    // 🎟 Ticket Minting (requires CRYLO hold)
    // ======================================
    function mint() public {
        require(CRYLO_TOKEN.balanceOf(msg.sender) >= minHoldUsd, "Insufficient CRYLO hold");
        require(CRYLO_TOKEN.allowance(msg.sender, address(this)) >= ticketPriceUsd, "Approve CRYLO first");
        require(CRYLO_TOKEN.transferFrom(msg.sender, address(this), ticketPriceUsd), "Transfer failed");
        _safeMint(msg.sender, nextTicketId);
        emit TicketMinted(msg.sender, nextTicketId, ticketPriceUsd);
        nextTicketId++;
        totalTicketsSold++;
    }

    // ===================================
    // 🚀 Request Random Winner from VRF
    // ===================================
    function requestRandomWinner() external onlyOwnerOrScheduler returns (uint256 requestId) {
        require(totalTicketsSold > 0, "No tickets sold");
        // This will trigger Chainlink VRF request
        requestId = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        lastRequestId = requestId;
    }

    // ===================================
    // 🎯 Fulfilled by Chainlink VRF
    // ===================================
    function fulfillRandomWords(uint256 /* requestId */, uint256[] memory randomWords) internal override {
        require(randomWords.length > 0, "No random word received");
        uint256 winningTicketId = (randomWords[0] % totalTicketsSold) + 1;
        address winner = ownerOf(winningTicketId);
        emit WinnerSelected(winner, winningTicketId);
        lastRandomWord = randomWords[0];
    }

    // ============================
    // 💸 Admin Functions
    // ============================
    function withdraw(uint256 amount) public onlyOwner {
        require(CRYLO_TOKEN.transfer(devWallet, amount), "Withdrawal failed");
    }

    function setTicketPriceUsd(uint256 _newPrice) public onlyOwner {
        ticketPriceUsd = _newPrice;
    }

    function setMinHoldUsd(uint256 _newMinHold) public onlyOwner {
        minHoldUsd = _newMinHold;
    }

    function setCallbackGasLimit(uint32 _limit) public onlyOwner {
        callbackGasLimit = _limit;
    }

    function setScheduler(address _s) external onlyOwner {
        scheduler = _s;
    }
}