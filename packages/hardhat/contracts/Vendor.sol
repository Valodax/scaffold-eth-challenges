pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    // our erc20 token "YourToken.sol" contract
    YourToken yourToken;

    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }

    // token price
    uint256 public constant tokensPerEth = 100;
    // Events
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(
        address buyer,
        uint256 amountOfETH,
        uint256 amountOfTokens
    );

    function buyTokens() external payable {
        require(msg.value > 0, "You need to send some ETH");

        uint256 amountOfTokens = msg.value * tokensPerEth;
        uint256 vendorBalance = yourToken.balanceOf(address(this));
        require(
            vendorBalance >= amountOfTokens,
            "The seller does not have enough tokens"
        );

        // Send tokens
        bool success = yourToken.transfer(msg.sender, amountOfTokens);
        require(success, "Token transfer failed");

        emit BuyTokens(msg.sender, msg.value, amountOfTokens);
    }

    // ToDo: create a withdraw() function that lets the owner withdraw ETH
    function withdraw() external onlyOwner {
        uint256 vendorBalance = address(this).balance;
        require(vendorBalance > 0, "Vendor does not have any ETH to withdraw");

        //send the ETH
        (bool success, ) = msg.sender.call{value: vendorBalance}("");
        require(success, "Failed to withdraw");
    }

    // ToDo: create a sellTokens(uint256 _amount) function:
    function sellTokens(uint256 amount) external {
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
