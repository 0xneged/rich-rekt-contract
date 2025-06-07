// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RichRekt is Ownable {
  struct Player {
    uint256 lastPlayed;
    uint256 points;
  }

  mapping(address => Player) public players;
  mapping(address => bool) public hasPendingRequest;

  event GameRequested(address indexed player);
  event GameSettled(
    address indexed player,
    uint256 reward,
    uint256 totalPoints
  );

  // sets owner from msg.sender
  constructor() Ownable(msg.sender) {}

  modifier canPlay(address player) {
    require(
      block.timestamp - players[player].lastPlayed >= 1 days,
      "You can play once every 24 hours"
    );
    require(!hasPendingRequest[player], "You already have a pending request");
    _;
  }

  function requestPlay() external canPlay(msg.sender) {
    hasPendingRequest[msg.sender] = true;
    players[msg.sender].lastPlayed = block.timestamp;

    emit GameRequested(msg.sender);
  }

  function settleGame(address player, uint256 random) external onlyOwner {
    require(hasPendingRequest[player], "No pending game");

    uint256 roll = random % 100;
    uint256 reward;

    if (roll < 10) {
      // 10% chance
      reward = 1000 + (random % 9001); // 1000–10000
    } else {
      // 90% chance
      reward = 10 + (random % 91); // 10–100
    }

    players[player].points += reward;
    hasPendingRequest[player] = false;

    emit GameSettled(player, reward, players[player].points);
  }

  function getPlayer(
    address player
  ) external view returns (uint256 lastPlayed, uint256 points) {
    Player memory p = players[player];
    return (p.lastPlayed, p.points);
  }
}
