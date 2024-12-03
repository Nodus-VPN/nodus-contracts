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

    function swapTokenToToken(string memory _fromSymbol, string memory _toSymbol, uint _amount) external {
        // _amount уже домножен на token.precision
        require(tokens[_fromSymbol].token.balanceOf(msg.sender) >= _amount, "Insufficient client balance");
        
        uint sum = _amount.mul(tokens[_fromSymbol].price); 
        uint amountToGet = sum.div(tokens[_toSymbol].price);

        require(tokens[_toSymbol].token.balanceOf(address(this)) >= amountToGet, "Insufficient contract balance");

        tokens[_fromSymbol].token.transferFrom(msg.sender, address(this), _amount);
        tokens[_toSymbol].token.transfer(msg.sender, amountToGet);
    }

    function swapEthToToken(string memory _toSymbol) external payable {
        require(msg.value <= msg.sender.balance, "Insufficient client balance");

        uint sum = msg.value.mul(PRECISION);
        uint amountToGet = sum.div(tokens[_toSymbol].price);

        require(tokens[_toSymbol].token.balanceOf(address(this)) >= amountToGet, "Insufficient contract balance");
        tokens[_toSymbol].token.transfer(msg.sender, amountToGet);
    }

    function swapTokenToETH(string memory _fromSymbol, uint256 _amount) external {
        require(tokens[_fromSymbol].token.balanceOf(msg.sender) >= _amount, "Insufficient client balance");

        uint sum = _amount.mul(tokens[_fromSymbol].price);
        uint amountToGet = sum.div(PRECISION);

        tokens[_fromSymbol].token.transferFrom(msg.sender, address(this), _amount);
        payable(msg.sender).transfer(amountToGet);
    }
} 