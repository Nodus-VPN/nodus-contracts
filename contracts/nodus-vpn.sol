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

    // Client
    struct Client {
        address clientAddress;
        uint256 subscriptionExpirationDate;
        uint256 availabeTraffic;
    }


    struct Node {
        uint okResponse;
        uint failedResponse;
        uint downloadSpeed;
        uint uploadSpeed;
        uint packageLoss;
        uint ping;
    }

    mapping(address => Client) public clients;
    address[] public clientList;

    // Node
    string[] public allNode;
    mapping(uint256 => address) public nodeOwners;
    mapping(string => Node) public nodeMetrics;
    event SetNode(uint node_id, string node_ip, address node_owner);
    

    constructor(address _nds_address) Ownable(msg.sender) {
        NDS = IERC20(_nds_address);
    }


    function getClientBalance(address _clientAddress) external view returns(uint256) {
        return NDS.balanceOf(_clientAddress);
    }

    // Node
    function setNodeIP(string memory _ip) external {
        nodeOwners[allNode.length] = msg.sender;
        allNode.push(_ip);

        emit SetNode(allNode.length, _ip, msg.sender);
    }

    function getAllNode() external view returns(string[] memory) {
        return allNode;
    }

    function getNodeMetrics(string memory _nodeIP) external view returns(Node memory) {
        return nodeMetrics[_nodeIP];
    }

    function updateNodeMetrics(
        string[] memory _nodeIP,
        uint[] memory _okResponse,
        uint[] memory _failedResponse,
        uint[] memory _downloadSpeed,
        uint[] memory _uploadSpeed,
        uint[] memory _packageLoss,
        uint[] memory _ping
    ) external {
        for (uint i = 0; i < _nodeIP.length; i++) {
            nodeMetrics[_nodeIP[i]].okResponse += _okResponse[i];
            nodeMetrics[_nodeIP[i]].failedResponse += _failedResponse[i];
            nodeMetrics[_nodeIP[i]].downloadSpeed = _downloadSpeed[i];
            nodeMetrics[_nodeIP[i]].uploadSpeed = _uploadSpeed[i];
            nodeMetrics[_nodeIP[i]].packageLoss = _packageLoss[i];
            nodeMetrics[_nodeIP[i]].ping = _ping[i];
        }
    }
}