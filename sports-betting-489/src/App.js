import logo from './logo.svg';
import './App.css';

import React, { useState, useEffect } from 'react';
import Web3 from 'web3';
import contract from '@truffle/contract';
import bettingApp from './/abi/bettingApp.json';
const MyContract = contract(MyContractJSON);


// Call the function to initialize Web3 and set the provider
//initWeb3();


function App() {
  const [web3, setWeb3] = useState(undefined);
  const [myContract, setMyContract] = useState(undefined);
  const [accounts, setAccounts] = useState([]);
  const [betAmount, setBetAmount] = useState('');
  const [teamSelected, setTeamSelected] = useState('');

  useEffect(() => {
    const init = async () => {
      const web3 = new Web3(Web3.givenProvider || 'http://localhost:8545');
      const accounts = await web3.eth.getAccounts();
      const myContract = contract(MyContractJSON);
      myContract.setProvider(web3.currentProvider);
      setWeb3(web3);
      setAccounts(accounts);
      setMyContract(myContract);
    };
    init();
  }, []);

  const handleBet = async () => {
    if (web3 && myContract && accounts && teamSelected) {
      const instance = await myContract.deployed();
      const weiValue = web3.utils.toWei(betAmount, 'ether');
      await instance.bet(teamSelected, { from: accounts[0], value: weiValue });
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Betting App</h1>
        <div>
          <input
            type="number"
            placeholder="Bet amount (in Ether)"
            value={betAmount}
            onChange={(e) => setBetAmount(e.target.value)}
          />
          <select
            value={teamSelected}
            onChange={(e) => setTeamSelected(e.target.value)}
          >
            <option value="">Select Team</option>
            <option value="1">Team 1</option>
            <option value="2">Team 2</option>
          </select>
          <button onClick={handleBet}>Place Bet</button>
        </div>
      </header>
    </div>
  );
}

export default App;
