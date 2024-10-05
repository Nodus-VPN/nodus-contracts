// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    // Храним токены на балансе этого контракта
    // Для тестнета сделать управление токенов send(address to) onlyOwner
    constructor() ERC20("Nodus", "NDS") Ownable(msg.sender) {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }
}
