// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DAO is Ownable {
    IERC20 public NDS;

    struct MemberDAO {
        uint id;
        uint balance;
    }
    address[] allMemberDAO;
    mapping(address => MemberDAO) public memberDAO;


    constructor(address _ndsAddress) Ownable(msg.sender) {
        NDS = IERC20(_ndsAddress);
    }


    function addAmountToBalance(address[] memory _allMemberDAO, uint[] memory _amountList) external onlyOwner {
        for (uint idx = 0; idx < _allMemberDAO.length ; idx++){
            address meberDaoAddress = _allMemberDAO[idx];
            memberDAO[meberDaoAddress].balance += _amountList[idx];
        }
    }

    function withdraw(uint amount) external {
        NDS.transferFrom(address(this), msg.sender, amount);
    }
}