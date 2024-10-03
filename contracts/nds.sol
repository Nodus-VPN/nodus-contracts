// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

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
        // (bool success,) = msg.sender.call{value: initialSupply / 2, gas: 2}("");
        // require(success == true);
    }

    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}