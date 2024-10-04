// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    // Храним токены на балансе этого контракта
    // Для тестнета сделать управление токенов send(address to) onlyOwner
    constructor(address _owner) ERC20("Nodus", "NDS") Ownable(msg.sender) {
        _mint(_owner, 1000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
