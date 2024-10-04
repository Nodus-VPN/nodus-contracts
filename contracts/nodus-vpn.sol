// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/nodus-token.sol";

contract NodusVPN is Ownable {
    NodusToken public token;
    constructor() Ownable(msg.sender) {
        token = new NodusToken(msg.sender);
    }    
}