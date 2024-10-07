// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// constant Faucet {
//     // типо сейл
// }

contract NodusVPN is Ownable {
    struct Client {
        address clientAddress;
        uint256 balance;
        uint256 txBlock;
    }

    IERC20 public NDS;

    string[] public availableNodes;
    address[] public clientList;

    mapping(uint256 => address) public nodeOwners;
    mapping(address => Client) public clients;
    
    event SetNode(uint node_id, string node_ip, address node_owner);
    event BalanceToppedUp(address indexed clientAddress, uint256 amount, uint256 blockNumber);

    constructor(address _nds_address) Ownable(msg.sender) {
        NDS = IERC20(_nds_address);
    }

    function topUpBalance(address _clientAddress, uint256 _amount, uint256 _txBlock) public {
        if (clients[_clientAddress].clientAddress == address(0)) {
            clientList.push(_clientAddress);
        }

        clients[_clientAddress] = Client({
            clientAddress: _clientAddress,
            balance: clients[_clientAddress].balance + _amount,
            txBlock: _txBlock
        });

        emit BalanceToppedUp(_clientAddress, _amount, _txBlock);
    }

    function getClientBalance(address _clientAddress) external view returns(uint256) {
        return clients[_clientAddress].balance;
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