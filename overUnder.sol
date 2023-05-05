pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

contract OverUnderBetting {
    using Counters for Counters.Counter;

    struct Bet {
        address bettor;
        uint256 amount;
        bool over;
    }

    address public oracle;
    uint256 public overUnderLine;
    bool public eventFinished;
    uint256 public eventResult;

    Counters.Counter private _betIds;
    mapping(uint256 => Bet) public bets;
    mapping(bool => uint256) public betAmounts;
    mapping(address => uint256) public pendingWithdrawals;

    event BetPlaced(uint256 indexed betId, address indexed bettor, uint256 amount, bool over);
    event BetSettled(uint256 indexed betId, address indexed bettor, uint256 amount);
    event Withdrawal(address indexed bettor, uint256 amount);

    constructor(uint256 _overUnderLine) {
        oracle = msg.sender;
        overUnderLine = _overUnderLine;
    }


    modifier eventNotDone() {
        require(!eventFinished, "the event is done");
        _;
    }

    modifier onlyOwner() {  
        require(msg.sender == oracle, "you aren't the oracle");
        _;
    }

    function placeBet(bool over) external payable eventNotDone {
        _betIds.increment();
        uint256 betId = _betIds.current();

        bets[betId] = Bet(msg.sender, msg.value, over);
        betAmounts[over] += msg.value;

        emit BetPlaced(betId, msg.sender, msg.value, over);
    }

    function settleBets(uint256 _eventResult) external onlyOwner {
        require(!eventFinished, "the bets have already been settled");

        eventFinished = true;
        eventResult = _eventResult;

        bool winningOutcome = _eventResult > overUnderLine;

        uint256 totalWinningBets = betAmounts[winningOutcome];
        uint256 totalLosingBets = betAmounts[!winningOutcome];

        for (uint256 x = 1; x <= _betIds.current(); x++) {
            Bet storage bet = bets[x];
            if (bet.over == winningOutcome) {
                uint256 payout = (bet.amount * totalLosingBets) / totalWinningBets;
                uint256 totalPayout = bet.amount + payout;
                pendingWithdrawals[bet.bettor] += totalPayout;
                emit BetSettled(x, bet.bettor, totalPayout);
            }
        }
    }

    function withdraw() external {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "You have nothing to withdraw");

        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit Withdrawal(msg.sender, amount);
    }
}

