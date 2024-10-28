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

        uint wgDownloadSpeedRN;
        uint wgUploadSpeedRN;
        uint wgPackageLossRN;
        uint wgPingRN;

        uint[] wgDownloadSpeedTS;
        uint[] wgUploadSpeedTS;
        uint[] wgPackageLossTS;
        uint[] wgPingTS;

        uint ovpnDownloadSpeedRN;
        uint ovpnUploadSpeedRN;
        uint ovpnPackageLossRN;
        uint ovpnPingRN;

        uint[] ovpnDownloadSpeedTS;
        uint[] ovpnUploadSpeedTS;
        uint[] ovpnPackageLossTS;
        uint[] ovpnPingTS;

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

    function updateNodeOvpnMetrics(
        string[] memory _nodeIP,
        uint[] memory _ovpnDownloadSpeed,
        uint[] memory _ovpnUploadSpeed,
        uint[] memory _ovpnPackageLoss,
        uint[] memory _ovpnPing
    ) external onlyOwner {
        for (uint nodeID = 0; nodeID < _nodeIP.length; nodeID++) {
            string memory nodeIP = _nodeIP[nodeID];
            nodeMetrics[nodeIP].ovpnDownloadSpeedRN = _ovpnDownloadSpeed[nodeID];
            nodeMetrics[nodeIP].ovpnUploadSpeedRN = _ovpnUploadSpeed[nodeID];
            nodeMetrics[nodeIP].ovpnPackageLossRN = _ovpnPackageLoss[nodeID];
            nodeMetrics[nodeIP].ovpnPingRN = _ovpnPing[nodeID];
            
            nodeMetrics[nodeIP].ovpnDownloadSpeedTS.push(_ovpnDownloadSpeed[nodeID]);
            nodeMetrics[nodeIP].ovpnUploadSpeedTS.push(_ovpnUploadSpeed[nodeID]);
            nodeMetrics[nodeIP].ovpnPackageLossTS.push(_ovpnPackageLoss[nodeID]);
            nodeMetrics[nodeIP].ovpnPingTS.push(_ovpnPing[nodeID]);
        }
    }

    function updateNodeWgMetrics(
        string[] memory _nodeIP,
        uint[] memory _wgDownloadSpeed,
        uint[] memory _wgUploadSpeed,
        uint[] memory _wgPackageLoss,
        uint[] memory _wgPing
    ) external onlyOwner {
        for (uint nodeID = 0; nodeID < _nodeIP.length; nodeID++) {
            string memory nodeIP = _nodeIP[nodeID];
            nodeMetrics[nodeIP].wgDownloadSpeedRN = _wgDownloadSpeed[nodeID];
            nodeMetrics[nodeIP].wgUploadSpeedRN = _wgUploadSpeed[nodeID];
            nodeMetrics[nodeIP].wgPackageLossRN = _wgPackageLoss[nodeID];
            nodeMetrics[nodeIP].wgPingRN = _wgPing[nodeID];
            
            nodeMetrics[nodeIP].wgDownloadSpeedTS.push(_wgDownloadSpeed[nodeID]);
            nodeMetrics[nodeIP].wgUploadSpeedTS.push(_wgUploadSpeed[nodeID]);
            nodeMetrics[nodeIP].wgPackageLossTS.push(_wgPackageLoss[nodeID]);
            nodeMetrics[nodeIP].wgPingTS.push(_wgPing[nodeID]);
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
        uint wgAvgPing = calculateWgAvgPing(nodeIP);
        uint wgAvgUploadSpeed = calculateWgAvgUploadSpeed(nodeIP);
        uint wgAvgDownloadSpeed = calculateWgAvgDownloadSpeed(nodeIP);
        uint wgAvgPackegLoss = calculateWgAvgPackegeLoss(nodeIP);

        uint score = (uptime * UPTIME_WEIGHT) +
                     ((wgAvgUploadSpeed) * UPLOAD_WEIGHT) +
                     ((wgAvgDownloadSpeed)  * DOWNLOAD_WEIGHT) -
                     ((wgAvgPing) * PING_WEIGHT) -
                     ((wgAvgPackegLoss) * LOSS_WEIGHT);

        return score;
    }

    function calculateWgAvgPackegeLoss(string memory nodeIP) internal view returns(uint) {
        uint[] memory packageLossTS = nodeMetrics[nodeIP].wgPackageLossTS;
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

    function calculateOvpnAvgPackegeLoss(string memory nodeIP) internal view returns(uint) {
        uint[] memory packageLossTS = nodeMetrics[nodeIP].ovpnPackageLossTS;
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

    function calculateWgAvgDownloadSpeed(string memory nodeIP) internal view returns(uint) {
        uint[] memory downloadSpeedTS = nodeMetrics[nodeIP].wgDownloadSpeedTS;
        uint totalDownloadSpeed = 0;
        for (uint downloadSpeedIDX = 0; downloadSpeedIDX < downloadSpeedTS.length; downloadSpeedIDX++) {
            totalDownloadSpeed += downloadSpeedTS[downloadSpeedIDX];
        }

        uint avgDownloadSpeed = (totalDownloadSpeed * PRECISION) / downloadSpeedTS.length;
        return avgDownloadSpeed;
    }

    function calculateOvpnAvgDownloadSpeed(string memory nodeIP) internal view returns(uint) {
        uint[] memory downloadSpeedTS = nodeMetrics[nodeIP].ovpnDownloadSpeedTS;
        uint totalDownloadSpeed = 0;
        for (uint downloadSpeedIDX = 0; downloadSpeedIDX < downloadSpeedTS.length; downloadSpeedIDX++) {
            totalDownloadSpeed += downloadSpeedTS[downloadSpeedIDX];
        }

        uint avgDownloadSpeed = (totalDownloadSpeed * PRECISION) / downloadSpeedTS.length;
        return avgDownloadSpeed;
    }

    function calculateWgAvgUploadSpeed(string memory nodeIP) internal view returns(uint) {
        uint[] memory uploadSpeedTS = nodeMetrics[nodeIP].wgUploadSpeedTS;
        uint totalUploadSpeed = 0;
        for (uint uploadSpeedIDX = 0; uploadSpeedIDX < uploadSpeedTS.length; uploadSpeedIDX++) {
            totalUploadSpeed += uploadSpeedTS[uploadSpeedIDX];
        }

        uint avgUploadSpeed = (totalUploadSpeed * PRECISION) / uploadSpeedTS.length;
        return avgUploadSpeed;
    }

    function calculateOvpnAvgUploadSpeed(string memory nodeIP) internal view returns(uint) {
        uint[] memory uploadSpeedTS = nodeMetrics[nodeIP].ovpnUploadSpeedTS;
        uint totalUploadSpeed = 0;
        for (uint uploadSpeedIDX = 0; uploadSpeedIDX < uploadSpeedTS.length; uploadSpeedIDX++) {
            totalUploadSpeed += uploadSpeedTS[uploadSpeedIDX];
        }

        uint avgUploadSpeed = (totalUploadSpeed * PRECISION) / uploadSpeedTS.length;
        return avgUploadSpeed;
    }

    function calculateWgAvgPing(string memory nodeIP) internal view returns(uint) {
        uint[] memory pingTS = nodeMetrics[nodeIP].wgPingTS;
        uint totalPing = 0;
        for (uint pingIDX = 0; pingIDX < pingTS.length; pingIDX++) {
            totalPing += pingTS[pingIDX];
        }

        uint avgPing = (totalPing * PRECISION) / pingTS.length;
        return avgPing;
    }

    function calculateOvpnAvgPing(string memory nodeIP) internal view returns(uint) {
        uint[] memory pingTS = nodeMetrics[nodeIP].ovpnPingTS;
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