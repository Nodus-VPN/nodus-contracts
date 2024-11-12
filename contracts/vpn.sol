// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract VPN is Ownable {
    IERC20 public NDS;
    uint public subscriptionMounthPrice = 10;


    struct Client {
        string hashedKey;
        uint subscriptionExpirationDate;
    }
    address[] public  allClientAddress;
    mapping(address => Client) public clients;
    

    struct Node {
        uint id;

        string status;
        address owner;

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

    string[] public allNodeIp;
    mapping(string => Node) public nodes;
    

    constructor(address _nds_address) Ownable(msg.sender) {
        NDS = IERC20(_nds_address);
    }
    

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


    function setNodeIP(string memory _nodeIP) external {
        Node memory node;
        node.id = allNodeIp.length;
        node.status = "active";
        node.owner = msg.sender;

        nodes[_nodeIP] = node;
        allNodeIp.push(_nodeIP);
    }

    function getAllNodeIp() external view returns(string[] memory) {
        return allNodeIp;
    }

    function getNode(string memory _nodeIP) external view returns(Node memory) {
        return nodes[_nodeIP];
    }

    function deleteNode(string[] memory _nodeIP) external onlyOwner {
        for (uint nodeID = 0; nodeID < _nodeIP.length; nodeID++) {
            string memory nodeIP = _nodeIP[nodeID];

            Node memory node = nodes[nodeIP];
            allNodeIp[node.id] = "";
            delete nodes[nodeIP];
        }
        
    }

    function updateNodeUptime(
        string[] memory _nodeIP,
        uint[] memory _okResponse,
        uint[] memory _failedResponse
    ) external onlyOwner {
        for (uint nodeID = 0; nodeID < _nodeIP.length; nodeID++) {
            string memory nodeIP = _nodeIP[nodeID];

            nodes[nodeIP].okResponse += _okResponse[nodeID];
            nodes[nodeIP].failedResponse += _failedResponse[nodeID];
        }
    }

    function updateNodeStatus(string[] memory _nodeIP, string memory _status) external onlyOwner {
        for (uint nodeID = 0; nodeID < _nodeIP.length; nodeID++) {
            string memory nodeIP = _nodeIP[nodeID];

            nodes[nodeIP].status = _status;
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
            
            nodes[nodeIP].downloadSpeedRN = _downloadSpeed[nodeID];
            nodes[nodeIP].uploadSpeedRN = _uploadSpeed[nodeID];
            nodes[nodeIP].packageLossRN = _packageLoss[nodeID];
            nodes[nodeIP].pingRN = _ping[nodeID];
            
            nodes[nodeIP].downloadSpeedTS.push(_downloadSpeed[nodeID]);
            nodes[nodeIP].uploadSpeedTS.push(_uploadSpeed[nodeID]);
            nodes[nodeIP].packageLossTS.push(_packageLoss[nodeID]);
            nodes[nodeIP].pingTS.push(_ping[nodeID]);
        }
    }

    uint constant UPTIME_WEIGHT = 40;
    uint constant PING_WEIGHT = 20;
    uint constant UPLOAD_WEIGHT = 15;
    uint constant DOWNLOAD_WEIGHT = 15;
    uint constant LOSS_WEIGHT = 10;
    uint constant PRECISION = 1e3;

    function calculateReward() external onlyOwner {
        uint totalScore = 0;
        uint totalNDS = NDS.balanceOf(address(this));
        for (uint nodeID = 0; nodeID < allNodeIp.length; nodeID++) {
            string memory nodeIP = allNodeIp[nodeID];
            totalScore += calculateNodeScore(nodeIP);
        }

        for (uint nodeIDX = 0; nodeIDX < allNodeIp.length; nodeIDX++) {
            string memory nodeIP = allNodeIp[nodeIDX];
            uint nodeScore = calculateNodeScore(nodeIP);

            if (nodeScore == 0) {
                continue;
            }

            uint nodeReward = (nodeScore * totalNDS * PRECISION) / totalScore;
            nodes[nodeIP].reward = nodeReward;
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
        uint[] memory packageLossTS = nodes[nodeIP].packageLossTS;
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
        uint[] memory downloadSpeedTS = nodes[nodeIP].downloadSpeedTS;
        uint totalDownloadSpeed = 0;
        for (uint downloadSpeedIDX = 0; downloadSpeedIDX < downloadSpeedTS.length; downloadSpeedIDX++) {
            totalDownloadSpeed += downloadSpeedTS[downloadSpeedIDX];
        }

        uint avgDownloadSpeed = (totalDownloadSpeed * PRECISION) / downloadSpeedTS.length;
        return avgDownloadSpeed;
    }

    function calculateAvgUploadSpeed(string memory nodeIP) internal view returns(uint) {
        uint[] memory uploadSpeedTS = nodes[nodeIP].uploadSpeedTS;
        uint totalUploadSpeed = 0;
        for (uint uploadSpeedIDX = 0; uploadSpeedIDX < uploadSpeedTS.length; uploadSpeedIDX++) {
            totalUploadSpeed += uploadSpeedTS[uploadSpeedIDX];
        }

        uint avgUploadSpeed = (totalUploadSpeed * PRECISION) / uploadSpeedTS.length;
        return avgUploadSpeed;
    }



    function calculateAvgPing(string memory nodeIP) internal view returns(uint) {
        uint[] memory pingTS = nodes[nodeIP].pingTS;
        uint totalPing = 0;
        for (uint pingIDX = 0; pingIDX < pingTS.length; pingIDX++) {
            totalPing += pingTS[pingIDX];
        }

        uint avgPing = (totalPing * PRECISION) / pingTS.length;
        return avgPing;
    }

    function calculateUptime(string memory nodeIP) internal view returns(uint) {
        uint okResponse = nodes[nodeIP].okResponse;
        uint failedResponse = nodes[nodeIP].failedResponse;

        uint totalResponses = okResponse + failedResponse;
        if (totalResponses == 0) {
            return 0;
        }
        uint uptime = (okResponse * PRECISION) / totalResponses;
        return uptime;
    }
}