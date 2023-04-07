pragma solidity ^0.8.12;
// SPDX-License-Identifier: GPL-3.0

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; //For uint to string conversion

contract bettingApp {
    using SafeMath for uint256;
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

    function bet(uint8 _teamSelected) public payable {
        //Limit the number of players betting to prevent potential gas issues when distributing prizes
        require(players.length < maxPlayers, "Maximum number of players reached.");
        //The first require is used to check if the player already exists
        require(!checkPlayerExists(msg.sender), "Player already exists.");
        //The bets should be either team 1 or team 2
        require(_teamSelected == 1 || _teamSelected == 2, "Please enter 1 or 2 for the two teams");
        //The second one is used to see if the value sent by the player is higher than the minimum value
        require(msg.value >= minimumBet, string.concat("Bet value must be higher than the minimum bet of ", Strings.toString(minimumBet)));
        require(msg.value <= maximumBet, string.concat("Bet value must be lower than the maximum bet of ", Strings.toString(maximumBet)));
        //We set the player information: amount of the bet and selected team
        playerInfo[msg.sender].amountBet = msg.value;
        playerInfo[msg.sender].teamSelected = _teamSelected;

        //then we add the address of the player to the players array
        players.push(msg.sender);
        //at the end, we increment the stakes of the team selected with the player bet
        if (_teamSelected == 1){
            totalBetsOne += msg.value;
        }
        else{
            totalBetsTwo += msg.value;
        }
        emit BetPlaced(msg.sender, msg.value, _teamSelected);
    }

    // Generates a number between 1 and 10 that will be the winner
    function distributePrizes(uint16 teamWinner) public {
        require(msg.sender == owner, "Only owner can distribute prizes");
        require(teamWinner == 1 || teamWinner == 2, "Please enter 1 or 2 for the two teams");
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
                //Transfer the money to the user, uses safemath to avoid integer overflow or underflow
                add.transfer(playerbet.mul((LoserBet.mul(10000).div(WinnerBet).add(10000)).div(10000)));
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




