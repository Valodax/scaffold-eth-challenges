pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    // Events
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(
        address buyer,
        uint256 amountOfETH,
        uint256 amountOfTokens
    );
    // our erc20 token "YourToken.sol" contract
    YourToken public yourToken;

    // token price
    uint256 public constant tokensPerEth = 100;

    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }

    // ToDo: create a payable buyTokens() function:
    function buyTokens() public payable {
        uint256 amountOfETH = msg.value;
        require(amountOfETH > 0, "You need to send some ETH");

        // Does the transferer have enough tokens?
        uint256 amountOfTokens = amountOfETH * tokensPerEth;
        uint256 vendorBalance = yourToken.balanceOf(address(this));
        require(
            vendorBalance >= amountOfTokens,
            "The seller does not have enough tokens"
        );

        // Send tokens
        address buyer = msg.sender;
        bool success = yourToken.transfer(buyer, amountOfTokens);
        require(success, "Token transfer failed");

        emit BuyTokens(buyer, amountOfETH, amountOfTokens);
    }

    // ToDo: create a withdraw() function that lets the owner withdraw ETH
    function withdraw() public onlyOwner {
        uint256 vendorBalance = address(this).balance;
        require(vendorBalance > 0, "Vendor does not have any ETH to withdraw");

        //send the ETH
        (bool success, ) = msg.sender.call{value: vendorBalance}("");
        require(success, "Failed to withdraw");
    }

    // ToDo: create a sellTokens(uint256 _amount) function:
    function sellTokens(uint256 amount) public {
        // validate amount
        require(amount > 0, "Amount must be greater than 0");

        // validate user has tokens to sell
        uint256 userBalance = yourToken.balanceOf(msg.sender);
        require(userBalance >= amount, "User does not have sufficient tokens");

        // do they have enough to sell?
        uint256 amountOfEth = amount / tokensPerEth;
        uint256 vendorEthBalance = address(this).balance;
        require(
            vendorEthBalance >= amountOfEth,
            "Vendor does not have enough ETH"
        );

        // transfer
        bool success = yourToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(success, "Failed to transfer tokens");

        // transfer ETH
        (success, ) = msg.sender.call{value: amountOfEth}("");
        require(success, "Failed to send back eth");

        // emit sell event
        emit SellTokens(msg.sender, amountOfEth, amount);
    }
}
