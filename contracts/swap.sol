// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Swap is Ownable {
    using SafeMath for uint256;
    uint public PRECISION  = 10000;

    struct Token {
        IERC20 token;
        uint price;
        uint precision;
    }
    string[] AllSymbol;
    mapping(string => Token) public tokens;

    constructor() Ownable(msg.sender) {
        
    }

    function addToken(string memory _tokenSymbol, address _tokenAddress, uint _price, uint _precision) external onlyOwner {
        // _price уже домножен на PRECISION
        IERC20 newToken = IERC20(_tokenAddress);
        tokens[_tokenSymbol] = Token(newToken, _price, _precision);
    }

    function swap(string memory _fromSymbol, string memory _toSymbol, uint _amount) external {
        require(tokens[_fromSymbol].token.balanceOf(msg.sender) >= _amount, "Insufficient client balance");
        require(tokens[_toSymbol].token.balanceOf(msg.sender) >= _amount, "Insufficient contract balance");

        uint sum = _amount.mul(tokens[_fromSymbol].price); 
        uint amountToGet = sum.div(tokens[_toSymbol].price);

        tokens[_fromSymbol].token.transferFrom(msg.sender, address(this), _amount * 10**tokens[_fromSymbol].precision);
        tokens[_toSymbol].token.transfer(msg.sender, amountToGet * 10**tokens[_toSymbol].precision);
    }

} 