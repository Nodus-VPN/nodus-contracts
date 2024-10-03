// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NDSToken is ERC20 {
    address private owner;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor(uint256 initialSupply) ERC20("Nodus", "NDS") {
        _mint(msg.sender, initialSupply);
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public isOwner {
        require(newOwner != address(0), "New owner should not be the zero address");
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}