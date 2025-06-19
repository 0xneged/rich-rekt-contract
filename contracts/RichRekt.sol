// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RichRekt is Ownable {
  uint256 public playCooldownHours = 6;
  struct Player {
    uint256 lastPlayed;
    uint256 points;
  }

  mapping(address => Player) public players;
  mapping(address => bool) public hasPendingRequest;
  mapping(address => address) public referrerOf;
  mapping(address => address[]) public referralsOf;

  event GameRequested(address indexed player, address indexed referrer);
  event GameSettled(
    address indexed player,
    uint256 reward,
    address indexed referrer,
    uint256 refReward
  );
  event Referred(address indexed player, address indexed referrer);

  constructor() Ownable(msg.sender) {}

  function getReferrals(
    address referrer
  ) external view returns (address[] memory) {
    return referralsOf[referrer];
  }

  modifier canPlay(address player) {
    require(
      block.timestamp - players[player].lastPlayed >=
        playCooldownHours * 1 hours,
      "Cooldown period has not passed yet"
    );
    require(!hasPendingRequest[player], "You already have a pending request");
    _;
  }

  function setPlayCooldownHours(uint256 updatedHours) external onlyOwner {
    require(updatedHours > 0, "Play cooldown must be positive");
    playCooldownHours = updatedHours;
  }

  function requestPlay(address referrer) external canPlay(msg.sender) {
    // Only record the referrer once
    if (
      referrerOf[msg.sender] == address(0) &&
      referrer != msg.sender &&
      referrer != address(0)
    ) {
      referrerOf[msg.sender] = referrer;
      referralsOf[referrer].push(msg.sender);
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

  function vanishTimestamp(address user) external onlyOwner {
    players[user].lastPlayed = 0;
  }
}
