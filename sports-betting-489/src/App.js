import React, { useState, useEffect } from 'react';
import Web3 from 'web3';
import logo from './logo.svg';
import './App.css';
import bettingApp from './abi/bettingApp.json';

const web3 = new Web3(Web3.givenProvider || 'http://localhost:7545');
const contractAddress = "0x4b846cCEF5D09d7C3b073b7F689E9A1A874C42eE";

let contract;

if (typeof web3 !== 'undefined') {
  contract = new web3.eth.Contract(bettingApp.abi, contractAddress);
} else {
  alert("Please install MetaMask or another web3 provider to interact with this app.");
}

function App() {
  const [players, setPlayers] = useState([{ teamNumber: '', ethAmount: '', account: '' }]);
  const [accounts, setAccounts] = useState([]);
  const [winningTeam, setWinningTeam] = useState('');

  useEffect(() => {
    const getAccounts = async () => {
      if (typeof web3 !== 'undefined') {
        const allAccounts = await web3.eth.getAccounts();
        setAccounts(allAccounts);
      }
    };
    getAccounts();

  }, []);

  const addPlayer = () => {
    setPlayers([...players, { teamNumber: '', ethAmount: '', account: '' }]);
  };

  const checkBalances = async () => {
    if (typeof web3 !== 'undefined') {
      for (const account of accounts) {
        const balance = await web3.eth.getBalance(account);
        console.log(`Balance of ${account}: ${web3.utils.fromWei(balance, 'ether')} ETH`);
      }
    }
  };

  const placeBet = async (team, ethAmount, account) => {
    if (!contract) {
      alert("Please connect to MetaMask and make sure the contract is loaded.");
      return;
    }

    const betAmount = Web3.utils.toWei(ethAmount, "ether");

    try {
      await contract.methods.commitBet(team).send({ from: account, value: betAmount });
      alert("Bet placed successfully!");
    } catch (error) {
      console.error("Error placing bet:", error);
      alert("Error placing bet. Check the console for more details.");
    }
  };

  const distributePrizes = async (winningTeamNumber) => {
    if (!contract) {
      alert("Please connect to MetaMask and make sure the contract is loaded.");
      return;
    }

    try {
      await contract.methods.distributePrizes(winningTeamNumber).send({ from: accounts[0] });
      alert("Prizes distributed successfully!");
      checkBalances();
    } catch (error) {
      console.error("Error distributing prizes:", error);
      alert("Error distributing prizes. Check the console for more details.");
    }
  };

  const revealBet = async (teamNumber, nonce, account) => {
    if (!contract) {
      alert("Please connect to MetaMask and make sure the contract is loaded.");
      return;
    }

    try {
      await contract.methods.revealBet(teamNumber, nonce).send({ from: account });
      alert("Bet revealed successfully!");
    } catch (error) {
      console.error("Error revealing bet:", error);
      alert("Error revealing bet. Check the console for more details.");
    }
  };

  
  return (
    <div className="App">
      <header className="App-header">
        <div className="players-container" style={{ display: 'flex', flexWrap: 'wrap' }}>
          {players.map((player, index) => (
            <div key={index} style={{ margin: '0 20px', minWidth: '200px' }}>
              <h3>Player {index + 1}</h3>
              <label>
                Team Number + Nonce Hash:
                <input
                  type="string"
                  value={player.teamNumber}
                  onChange={(e) => {
                    const newPlayers = [...players];
                    newPlayers[index].teamNumber = e.target.value;
                    setPlayers(newPlayers);
                  }}
                />
              </label>
              <label>
                Amount (ETH):
                <input
                  type="string"
                  value={player.ethAmount}
                  onChange={(e) => {
                    const newPlayers = [...players];
                    newPlayers[index].ethAmount = e.target.value;
                    setPlayers(newPlayers);
                  }}
                />
              </label>
              <label>
              Nonce:
              <input
                type="number"
                value={player.nonce}
                onChange={(e) =>
                  setPlayers(
                    players.map((p, i) =>
                      i === index ? { ...p, nonce: e.target.value } : p
                    )
                  )
                }
              />
            </label>

              <label>
                Account:
                <select
                  value={player.account}
                  onChange={(e) => {
                    const newPlayers = [...players];
                    newPlayers[index].account = e.target.value;
                    setPlayers(newPlayers);
                  }}
                >
                  <option value="">Select account</option>
                  {accounts.map((account, i) => (
                    <option key={i} value={account}>
                      {account}
                    </option>
                  ))}
                </select>
              </label>
              <button
                onClick={() => placeBet(player.teamNumber, player.ethAmount, player.account)}
              >
                Place Bet
              </button>
              <button
                onClick={() => revealBet(player.teamNumber, player.nonce, player.account)}
              >
                Reveal Bet
              </button>
            </div>
          ))}
        </div>
        <button onClick={addPlayer}>Add Player</button>
        <div>
          <label>
            Winning team:
            <input
              type="number"
              value={winningTeam}
              onChange={(e) => setWinningTeam(e.target.value)}
            />
          </label>
          <button onClick={() => distributePrizes(winningTeam)}>Distribute Prizes</button>
        </div>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
      </header>
    </div>
  );
}

export default App;