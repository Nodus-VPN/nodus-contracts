// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// constant Faucet {
//     // типо сейл
// }

contract NodusVPN is Ownable {
    IERC20 public NDS;

    string[] public availableNodes;
    address[] public allClinet;

    mapping (address => uint256) internal clientBalances;
    mapping (uint256 => address) public nodeOwners;
    
    event SetNode(uint node_id, string node_ip, address node_owner);

    constructor(address _nds_address) Ownable(msg.sender) {
        NDS = IERC20(_nds_address);
    }

    function getClientBalance(address _client) external view returns(uint256) {
        return clientBalances[_client];
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