// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NodusToken is ERC20, Ownable {
    constructor() ERC20("Nodus", "NDS") Ownable(msg.sender) {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }
}
