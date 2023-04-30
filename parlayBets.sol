pragma solidity ^0.8.0;

contract ParlayBets {
    address public owner;
    struct Bet {
        uint256 amount;
        uint8[] outcomes;
        bool claimed;
    }

    mapping(uint256 => mapping(address => Bet)) public bets;
    mapping(uint256 => uint8[]) public actualOutcomes;

    event BetPlaced(uint256 eventId, address indexed bettor, uint256 amount, uint8[] outcomes);
    event BetClaimed(uint256 eventId, address indexed bettor, uint256 amount);
    event OutcomesSet(uint256 eventId, uint8[] outcomes);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function placeBet(uint256 eventId, uint8[] memory outcomes) public payable {
        require(msg.value > 0, "Must send a positive amount of ETH");
        require(outcomes.length > 1, "Parlay bet must have at least 2 outcomes");

        Bet storage bet = bets[eventId][msg.sender];
        require(bet.amount == 0, "A bet has already been placed for this event by this bettor");

        bet.amount = msg.value;
        bet.outcomes = outcomes;
        bet.claimed = false;

        emit BetPlaced(eventId, msg.sender, msg.value, outcomes);
    }

    function setActualOutcomes(uint256 eventId, uint8[] memory outcomes) public onlyOwner {
        actualOutcomes[eventId] = outcomes;
        emit OutcomesSet(eventId, outcomes);
    }

    function claimBet(uint256 eventId) public {
        Bet storage bet = bets[eventId][msg.sender];
        uint8[] storage outcomes = actualOutcomes[eventId];
        require(!bet.claimed, "Bet already claimed");
        require(bet.amount > 0, "No bet has been placed for this event by this bettor");
        require(areEqual(bet.outcomes, outcomes), "Parlay bet outcomes do not match");

        uint256 amountToTransfer = bet.amount * 2; // Example payout: double the bet amount
        bet.claimed = true;
        payable(msg.sender).transfer(amountToTransfer);

        emit BetClaimed(eventId, msg.sender, amountToTransfer);
    }

    function areEqual(uint8[] memory a, uint8[] memory b) private pure returns (bool) {
        if (a.length != b.length) {
            return false;
        }
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }
}

