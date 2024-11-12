// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Swap {
    using SafeMath for uint256;

    struct TokenData {
        IERC20 token;
        uint256 rate;
    }

    mapping(string => TokenData) public tokenMapping;

    function addToken(string memory _tokenSymbol, address _tokenAddress, uint256 _rate) public {
        IERC20 newToken = IERC20(_tokenAddress);
        tokenMapping[_tokenSymbol] = TokenData(newToken, _rate);
    }

    function swap(string memory _fromSymbol, string memory _toSymbol, uint256 _amount) public {
        require(tokenMapping[_fromSymbol].token.balanceOf(msg.sender) >= _amount, "Insufficient balance");

        uint256 amountToGet = _amount.mul(tokenMapping[_toSymbol].rate).div(tokenMapping[_fromSymbol].rate);

        tokenMapping[_fromSymbol].token.transferFrom(msg.sender, address(this), _amount);
        tokenMapping[_toSymbol].token.transfer(msg.sender, amountToGet);
    }

    function changeRate(string memory _tokenSymbol, uint256 _newRate) public {
        tokenMapping[_tokenSymbol].rate = _newRate;
    }
}