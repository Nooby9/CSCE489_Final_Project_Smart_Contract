pragma solidity ^0.8.12;
// SPDX-License-Identifier: GPL-3.0
// Testing Purposes: Hash(Team, Nonce)
// Hash(1, 1) = 0x9b68e489a07c86105b2c34adda59d3851d6f33abd41be6e9559cf783147db5dd
// Hash(2, 1) = 0xc22f283e315b25ded781f41aadc4cc3421da0afd0704feaae04c34a9dfc55ac6

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; //For uint to string conversion
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
contract bettingApp {
    using SafeMath for uint256;
    using ECDSA for bytes32;
    address public owner;
    uint256 public minimumBet;
    uint256 public maximumBet;
    uint256 public totalBetsOne;
    uint256 public totalBetsTwo;
    uint256 public maxPlayers;
    address[] public players;

    struct Player {
        uint256 amountBet;
        uint16 teamSelected;
        bytes32 commit;
        bool revealed;
    }

    event BetPlaced(address indexed player, uint256 amount, uint8 teamSelected);
    event PrizesDistributed(uint16 winningTeam);
    // The address of the player and => the user info
    mapping(address => Player) public playerInfo;
    receive() external payable {}
    
    constructor() {
        owner = msg.sender;
        minimumBet = 100000000000000; //0.0001 ether
        maximumBet = 100000000000000000000; //100 ether
        maxPlayers = 1000;
    }

    function commitBet(bytes32 _commit) public payable {
        require(!checkPlayerExists(msg.sender), "Player already exists.");
        require(players.length < maxPlayers, "Maximum number of players reached.");
        require(msg.value >= minimumBet, string.concat("Bet value must be higher than the minimum bet of ", Strings.toString(minimumBet)));
        require(msg.value <= maximumBet, string.concat("Bet value must be lower than the maximum bet of ", Strings.toString(maximumBet)));

        playerInfo[msg.sender].commit = _commit;
        playerInfo[msg.sender].amountBet = msg.value;
        players.push(msg.sender);
    }

    function revealBet(uint8 _teamSelected, uint256 _nonce) public {
        require(checkPlayerExists(msg.sender), "Player doesn't exist.");
        require(!playerInfo[msg.sender].revealed, "Player has already revealed their bet.");

        bytes32 computedHash = keccak256(abi.encodePacked(_teamSelected, _nonce));

        require(playerInfo[msg.sender].commit == computedHash, "Provided bet details do not match the commit.");

        // The bets should be either team 1 or team 2
        require(_teamSelected == 1 || _teamSelected == 2, "Please enter 1 or 2 for the two teams");

        // We set the player information: selected team
        playerInfo[msg.sender].teamSelected = _teamSelected;
        playerInfo[msg.sender].revealed = true;

        // At the end, we increment the stakes of the team selected with the player bet
        if (_teamSelected == 1) {
            totalBetsOne += playerInfo[msg.sender].amountBet;
        } else {
            totalBetsTwo += playerInfo[msg.sender].amountBet;
        }

        emit BetPlaced(msg.sender, playerInfo[msg.sender].amountBet, _teamSelected);
    }

    function kill() public {
        require(msg.sender == owner, "Only owner can execute this function.");

        // Refund each player's bet
        for (uint256 i = 0; i < players.length; i++) {
            address payable playerAddress = payable(players[i]);
            uint256 playerbet = playerInfo[playerAddress].amountBet;

            if (playerbet > 0) {
                playerAddress.transfer(playerbet);
            }
            delete playerInfo[playerAddress];
        }

        while (players.length > 0) {
            players.pop();
        }

        // Destroy the contract and send any remaining balance to the owner
        selfdestruct(payable(owner));
    }

    function checkPlayerExists(address player) public view returns(bool){
        for(uint256 i = 0; i < players.length; i++){
            if(players[i] == player) return true;
        }
        return false;
    }

    // Generates a number between 1 and 10 that will be the winner
    function distributePrizes(uint16 teamWinner) public {
        
        require(msg.sender == owner, "Only owner can distribute prizes");
        require(teamWinner == 1 || teamWinner == 2, "Please enter 1 or 2 for the two teams");
        for (uint256 i = 0; i < players.length; i++) {
            address payable playerAddress = payable(players[i]);
            bool reveal = playerInfo[playerAddress].revealed;
            require(reveal, "Not all players have revealed.");
        }
        emit PrizesDistributed(teamWinner);
        //If no one bet on the winning team, return everyone's bets
        if((totalBetsOne==0 && teamWinner==1) || (totalBetsTwo==0 && teamWinner==2)){ 
            for (uint256 i = 0; i < players.length; i++) {
                address payable playerAddress = payable(players[i]);
                playerAddress.transfer(playerInfo[playerAddress].amountBet);
                delete playerInfo[playerAddress];
            }
            while (players.length > 0) {
                players.pop();
            }
            totalBetsOne = 0;
            totalBetsTwo = 0;
            return;
        }
        //Else, give the winners their prizes
        address[1000] memory winners;
        //We have to create a temporary in-memory array with fixed size
        //Let's choose 1000
        uint256 count = 0; // This is the count for the array of winners
        uint256 LoserBet = 0; //This will take the value of all losers bet
        uint256 WinnerBet = 0; //This will take the value of all winners bet

        //We loop through the player array to check who selected the winner team
        for(uint256 i = 0; i < players.length; i++){
            address playerAddress = players[i];

            //If the player selected the winner team
            //We add his address to the winners array
            if(playerInfo[playerAddress].teamSelected == teamWinner){
                winners[count] = playerAddress;
                count++;
            }
        }

        //We define which bet sum is the Loser one and which one is the winner
        if (teamWinner == 1){
            LoserBet = totalBetsTwo;
            WinnerBet = totalBetsOne;
        }
        else if (teamWinner == 2){
            LoserBet = totalBetsOne;
            WinnerBet = totalBetsTwo;
        }

        //We loop through the array of winners, to give ethers to the winners
        for(uint256 j = 0; j < count; j++){
            // Check that the address in this fixed array is not empty
            if(winners[j] != address(0)){
                address payable add = payable(winners[j]);
                uint256 playerbet = playerInfo[add].amountBet;
                
                //add.transfer((playerbet * (10000 + (LoserBet * 10000 / WinnerBet))) / 10000); //still has some rounding error
                //LoserBet * 10000 may be a large value, but it is never larger than uint256's max (115792089237316195423570985008687907853269984665640564039457584007913129639935)
                //as the number of players is limited to 1000 (max loser is 999) and the max wei is 100000000000000000000
                //Transfer the money to the user, using safemath to avoid integer overflow doesn't work
                uint256 intermediateResult = LoserBet.mul(10000).div(WinnerBet).add(10000);
                uint256 result = playerbet.mul(intermediateResult).div(10000);
                add.transfer(result);
                //note to self: without 10000: playbet + playerbet*LoserBet/WinnerBet
                //add.transfer(playerbet.mul((LoserBet.mul(10000).div(WinnerBet).add(10000)).div(10000))); doesn't produce correct result
            }
        }
        for (uint256 i = 0; i < players.length; i++) {
            address playerAddress = players[i];
            delete playerInfo[playerAddress]; // Delete all the players
        }
        while (players.length > 0) {
            players.pop();
        } // Delete all the players array
        LoserBet = 0; //reinitialize the bets
        WinnerBet = 0;
        totalBetsOne = 0;
        totalBetsTwo = 0;
    }
    function AmountOne() public view returns(uint256){
        return totalBetsOne;
    }

    function AmountTwo() public view returns(uint256){
        return totalBetsTwo;
    }
}
