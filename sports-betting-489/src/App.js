import React, { useState, useEffect } from 'react';
import Web3 from 'web3';
import logo from './logo.svg';
import './App.css';
import bettingApp from './abi/bettingApp.json';

const web3 = new Web3(Web3.givenProvider || 'http://localhost:7545');
const contractAddress = "0x1336CF0136778bc30c874D3875a68b3951B15925";

let contract;

if (typeof web3 !== 'undefined') {
  contract = new web3.eth.Contract(bettingApp.abi, contractAddress);
} else {
  alert("Please install MetaMask or another web3 provider to interact with this app.");
}

function App() {
  const [teamNumber, setTeamNumber] = useState('');
  const [ethAmount, setEthAmount] = useState('');

  const placeBet = async (team) => {
    if (!contract) {
      alert("Please connect to MetaMask and make sure the contract is loaded.");
      return;
    }

    const betAmount = Web3.utils.toWei(ethAmount, "ether");
    const accounts = await web3.eth.getAccounts();

    try {
      await contract.methods.commitBet(team).send({ from: accounts[0], value: betAmount });
      alert("Bet placed successfully!");
    } catch (error) {
      console.error("Error placing bet:", error);
      alert("Error placing bet. Check the console for more details.");
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <div>
          <label>
            Team number:
            <input
              type="string"
              value={teamNumber}
              onChange={(e) => setTeamNumber(e.target.value)}
            />
          </label>
          <label>
            Amount (ETH):
            <input
              type="text"
              value={ethAmount}
              onChange={(e) => setEthAmount(e.target.value)}
            />
          </label>
          <button onClick={() => placeBet(teamNumber)}>Place Bet</button>
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
