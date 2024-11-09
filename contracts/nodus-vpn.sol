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
    uint public subscriptionMounthPrice = 10;

    // Client
    struct Client {
        string hashedKey;
        uint subscriptionExpirationDate;
    }
    mapping(address => Client) public clients;
    address[] private allClientAddress;


    // Node
    struct Node {
        uint okResponse;
        uint failedResponse;

        uint downloadSpeedRN;
        uint uploadSpeedRN;
        uint packageLossRN;
        uint pingRN;

        uint[] downloadSpeedTS;
        uint[] uploadSpeedTS;
        uint[] packageLossTS;
        uint[] pingTS;

        uint reward;
    }

    string[] public allNode;
    mapping(string => address) public nodeOwners;
    mapping(string => Node) public nodeMetrics;

    event SetNode(uint node_id, string node_ip, address node_owner);
    

    constructor(address _nds_address) Ownable(msg.sender) {
        NDS = IERC20(_nds_address);
    }
    
    // Client
    function getClient(address _clientAddress) external view returns(Client memory) {
        return clients[_clientAddress];
    }

    function getAllClientAddress() external view returns(address[] memory) {
        return allClientAddress;
    }

    function getClientBalance() external view returns(uint) {
        return NDS.balanceOf(msg.sender);
    }


    function subscribe(
        uint _subscriptionDuration,
        string memory _hashedKey
    ) external {
        uint price = _subscriptionDuration * subscriptionMounthPrice;
        NDS.transferFrom(msg.sender, address(this), price);

        clients[msg.sender].subscriptionExpirationDate = block.timestamp + (_subscriptionDuration * 2 minutes);
        clients[msg.sender].hashedKey = _hashedKey;
        allClientAddress.push(msg.sender);
    }


    // Node
    function setNodeIP(string memory _nodeIP) external {
        nodeOwners[_nodeIP] = msg.sender;
        allNode.push(_nodeIP);

        emit SetNode(allNode.length, _nodeIP, msg.sender);
    }

    function getAllNode() external view returns(string[] memory) {
        return allNode;
    }

    function getNodeMetrics(string memory _nodeIP) external view returns(Node memory) {
        return nodeMetrics[_nodeIP];
    }

    function updateNodeUptime(
        string[] memory _nodeIP,
        uint[] memory _okResponse,
        uint[] memory _failedResponse
    ) external onlyOwner {
        for (uint nodeID = 0; nodeID < _nodeIP.length; nodeID++) {
            string memory nodeIP = _nodeIP[nodeID];
            nodeMetrics[nodeIP].okResponse += _okResponse[nodeID];
            nodeMetrics[nodeIP].failedResponse += _failedResponse[nodeID];
        }
    }


    function updateNodeMetrics(
        string[] memory _nodeIP,
        uint[] memory _downloadSpeed,
        uint[] memory _uploadSpeed,
        uint[] memory _packageLoss,
        uint[] memory _ping
    ) external onlyOwner {
        for (uint nodeID = 0; nodeID < _nodeIP.length; nodeID++) {
            string memory nodeIP = _nodeIP[nodeID];
            nodeMetrics[nodeIP].downloadSpeedRN = _downloadSpeed[nodeID];
            nodeMetrics[nodeIP].uploadSpeedRN = _uploadSpeed[nodeID];
            nodeMetrics[nodeIP].packageLossRN = _packageLoss[nodeID];
            nodeMetrics[nodeIP].pingRN = _ping[nodeID];
            
            nodeMetrics[nodeIP].downloadSpeedTS.push(_downloadSpeed[nodeID]);
            nodeMetrics[nodeIP].uploadSpeedTS.push(_uploadSpeed[nodeID]);
            nodeMetrics[nodeIP].packageLossTS.push(_packageLoss[nodeID]);
            nodeMetrics[nodeIP].pingTS.push(_ping[nodeID]);
        }
    }

    uint constant UPTIME_WEIGHT = 40;
    uint constant PING_WEIGHT = 20;
    uint constant UPLOAD_WEIGHT = 15;
    uint constant DOWNLOAD_WEIGHT = 15;
    uint constant LOSS_WEIGHT = 10;
    uint constant PRECISION = 1e4;

    function calculateReward() external onlyOwner {
        uint totalScore = 0;
        uint totalNDS = NDS.balanceOf(address(this));
        for (uint nodeID = 0; nodeID < allNode.length; nodeID++) {
            string memory nodeIP = allNode[nodeID];
            totalScore += calculateNodeScore(nodeIP);
        }

        for (uint nodeIDX = 0; nodeIDX < allNode.length; nodeIDX++) {
            string memory nodeIP = allNode[nodeIDX];
            uint nodeScore = calculateNodeScore(nodeIP);

            if (nodeScore == 0) {
                continue;
            }

            uint nodeReward = (nodeScore * totalNDS * PRECISION) / totalScore;
            nodeMetrics[nodeIP].reward = nodeReward;
        }
    }

    

    function calculateNodeScore(string memory nodeIP) public view returns (uint) {
        uint uptime = calculateUptime(nodeIP);
        uint avgPing = calculateAvgPing(nodeIP);
        uint avgUploadSpeed = calculateAvgUploadSpeed(nodeIP);
        uint avgDownloadSpeed = calculateAvgDownloadSpeed(nodeIP);
        uint avgPackegLoss = calculateAvgPackegeLoss(nodeIP);

        uint score = (uptime * UPTIME_WEIGHT) +
                     (avgUploadSpeed * UPLOAD_WEIGHT) +
                     (avgDownloadSpeed  * DOWNLOAD_WEIGHT) -
                     (avgPing * PING_WEIGHT) -
                     (avgPackegLoss * LOSS_WEIGHT);

        return score;
    }

    function calculateAvgPackegeLoss(string memory nodeIP) internal view returns(uint) {
        uint[] memory packageLossTS = nodeMetrics[nodeIP].packageLossTS;
        uint totalPackageLoss = 0;
        for (uint packageLossIDX = 0; packageLossIDX < packageLossTS.length; packageLossIDX++) {
            totalPackageLoss += packageLossTS[packageLossIDX];
        }
        if (totalPackageLoss == 0) {
            return 0;
        }

        uint avgPackegLoss = (totalPackageLoss * PRECISION) / packageLossTS.length;
        return avgPackegLoss;
    }

    
    function calculateAvgDownloadSpeed(string memory nodeIP) internal view returns(uint) {
        uint[] memory downloadSpeedTS = nodeMetrics[nodeIP].downloadSpeedTS;
        uint totalDownloadSpeed = 0;
        for (uint downloadSpeedIDX = 0; downloadSpeedIDX < downloadSpeedTS.length; downloadSpeedIDX++) {
            totalDownloadSpeed += downloadSpeedTS[downloadSpeedIDX];
        }

        uint avgDownloadSpeed = (totalDownloadSpeed * PRECISION) / downloadSpeedTS.length;
        return avgDownloadSpeed;
    }

    function calculateAvgUploadSpeed(string memory nodeIP) internal view returns(uint) {
        uint[] memory uploadSpeedTS = nodeMetrics[nodeIP].uploadSpeedTS;
        uint totalUploadSpeed = 0;
        for (uint uploadSpeedIDX = 0; uploadSpeedIDX < uploadSpeedTS.length; uploadSpeedIDX++) {
            totalUploadSpeed += uploadSpeedTS[uploadSpeedIDX];
        }

        uint avgUploadSpeed = (totalUploadSpeed * PRECISION) / uploadSpeedTS.length;
        return avgUploadSpeed;
    }



    function calculateAvgPing(string memory nodeIP) internal view returns(uint) {
        uint[] memory pingTS = nodeMetrics[nodeIP].pingTS;
        uint totalPing = 0;
        for (uint pingIDX = 0; pingIDX < pingTS.length; pingIDX++) {
            totalPing += pingTS[pingIDX];
        }

        uint avgPing = (totalPing * PRECISION) / pingTS.length;
        return avgPing;
    }

    function calculateUptime(string memory nodeIP) internal view returns(uint) {
        uint okResponse = nodeMetrics[nodeIP].okResponse;
        uint failedResponse = nodeMetrics[nodeIP].failedResponse;

        uint totalResponses = okResponse + failedResponse;
        if (totalResponses == 0) {
            return 0;
        }
        uint uptime = (okResponse * PRECISION) / totalResponses;
        return uptime;
    }
}