// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Faucet is Ownable {
    mapping(address => uint) public lastPullTime;
    uint pullAmount = 0.015 ether;
    uint cooldownTime = 5 minutes;

    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    function pull() external {
        require(address(this).balance >= pullAmount, "Not enough contract balance");
        uint lastTime = lastPullTime[msg.sender];
        require(block.timestamp >= lastTime + cooldownTime, "Retry in 5 minute");

        lastPullTime[msg.sender] = block.timestamp;
        (bool success, ) = msg.sender.call{value: pullAmount}("");
        require(success, "Failed");
    }
}