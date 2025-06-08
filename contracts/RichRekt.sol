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
  mapping(address => address) public referrerOf;

  event GameRequested(address indexed player, address indexed referrer);
  event GameSettled(
    address indexed player,
    uint256 reward,
    address indexed referrer,
    uint256 refReward
  );
  event Referred(address indexed player, address indexed referrer);

  constructor() Ownable(msg.sender) {}

  modifier canPlay(address player) {
    require(
      block.timestamp - players[player].lastPlayed >= 1 days,
      "You can play once every 24 hours"
    );
    require(!hasPendingRequest[player], "You already have a pending request");
    _;
  }

  function requestPlay(address referrer) external canPlay(msg.sender) {
    // Only record the referrer once
    if (
      referrerOf[msg.sender] == address(0) &&
      referrer != msg.sender &&
      referrer != address(0)
    ) {
      referrerOf[msg.sender] = referrer;
      emit Referred(msg.sender, referrer);
    }

    hasPendingRequest[msg.sender] = true;

    emit GameRequested(msg.sender, referrerOf[msg.sender]);
  }

  function settleGame(
    address player,
    uint256 random
  ) external onlyOwner returns (uint256 reward, uint256 newPoints) {
    require(hasPendingRequest[player], "No pending game");

    uint256 roll = random % 100;

    // 10% chance
    if (roll < 10) {
      reward = 1000 + (random % 9001); // 1000–10000
    } else {
      reward = 10 + (random % 91); // 10–100
    }

    // Apply referral bonus if applicable
    address referrer = referrerOf[player];
    uint256 refReward = 0;

    if (referrer != address(0)) {
      refReward = reward / 100; // 1%
      players[referrer].points += refReward;
    }

    players[player].points += reward;
    players[player].lastPlayed = block.timestamp;
    hasPendingRequest[player] = false;

    emit GameSettled(player, reward, referrer, refReward);
    return (reward, players[player].points);
  }

  function getPlayer(
    address player
  )
    external
    view
    returns (uint256 lastPlayed, uint256 points, address referrer)
  {
    Player memory p = players[player];
    return (p.lastPlayed, p.points, referrerOf[player]);
  }
}
