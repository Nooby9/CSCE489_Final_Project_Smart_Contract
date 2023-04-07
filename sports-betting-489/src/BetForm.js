import React, { useState } from 'react';
import { Form, Button } from 'react-bootstrap';

function BetForm(props) {
  const [betAmount, setBetAmount] = useState(0);
  const [teamSelected, setTeamSelected] = useState(0);

  const handleBetAmountChange = (event) => {
    setBetAmount(event.target.value);
  }

  const handleTeamSelectedChange = (event) => {
    setTeamSelected(event.target.value);
  }

  const handleSubmit = async (event) => {
    event.preventDefault();

    // Check if bet amount is valid
    if (betAmount < props.minimumBet || betAmount > props.maximumBet) {
      alert(`Bet amount must be between ${props.minimumBet} and ${props.maximumBet}`);
      return;
    }

    // Check if team selection is valid
    if (teamSelected !== "1" && teamSelected !== "2") {
      alert(`Please select either team 1 or team 2`);
      return;
    }

    // Place the bet using the contract instance
    try {
      const accounts = await window.ethereum.request({ method: 'eth_accounts' });
      const bettingApp = await MyContract.deployed();
      await bettingApp.bet(teamSelected, { from: accounts[0], value: betAmount });
      alert(`Bet placed successfully!`);
    } catch (error) {
      console.error(error);
      alert(`Error placing bet: ${error.message}`);
    }
  }

  return (
    <Form onSubmit={handleSubmit}>
      <Form.Group controlId="formBetAmount">
        <Form.Label>Bet Amount</Form.Label>
        <Form.Control type="number" placeholder="Enter bet amount" value={betAmount} onChange={handleBetAmountChange} />
      </Form.Group>

      <Form.Group controlId="formTeamSelected">
        <Form.Label>Select Team</Form.Label>
        <Form.Control as="select" value={teamSelected} onChange={handleTeamSelectedChange}>
          <option value="0">Select Team</option>
          <option value="1">Team 1</option>
          <option value="2">Team 2</option>
        </Form.Control>
      </Form.Group>

      <Button variant="primary" type="submit">
        Place Bet
      </Button>
    </Form>
  );
}

export default BetForm;
