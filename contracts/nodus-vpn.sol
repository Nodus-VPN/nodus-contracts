// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/nodus-token.sol";

contract NodusVPN is Ownable {
    NodusToken public token;

    mapping (address => uint256) internal clientBalances;
    mapping (uint256 => address) public nodeOwners;
    string[] public availableNodes;
    
    event SetNode(uint node_id, string node_ip, address node_owner);

    constructor() Ownable(msg.sender) {
        token = new NodusToken(msg.sender);
    }

    receive() external payable {
        clientBalances[msg.sender] = clientBalances[msg.sender] + msg.value;
    }

    function setNodeIP(string memory _ip) external {
        nodeOwners[availableNodes.length] = msg.sender;
        availableNodes.push(_ip);
        
        emit SetNode(availableNodes.length, _ip, msg.sender);
    }

    function getAllNode() external view returns(string[] memory) {
        return availableNodes;
    }
}