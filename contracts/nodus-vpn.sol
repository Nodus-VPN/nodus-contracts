// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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


// constant Faucet {
//     // типо сейл
// }

contract VPN is Ownable {

    IERC20 public NDS;
    string[] public availableNodes;
    mapping (address => uint256) internal clientBalances;
    mapping (uint256 => address) public nodeOwners;
    
    event SetNode(uint node_id, string node_ip, address node_owner);

    constructor(address _nds_address) Ownable(msg.sender) {
        NDS = IERC20(_nds_address);
    }

    receive() external payable {
        bool success = IERC20(NDS).transfer(msg.sender, msg.value);
        require(success);
        clientBalances[msg.sender] += msg.value;
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