// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    // External contract that will hold staked funds if threshold is reached
    ExampleExternalContract public exampleExternalContract;

    // User's Balance's mapping
    mapping(address => uint256) public balances;

    // Threshold
    uint256 public constant threshold = 1 ether;

    // Deadline
    uint256 public deadline = block.timestamp + 72 hours;

    // EVENTS
    event Stake(address sender, uint256 value);

    // MODIFIERS
    modifier notCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "Staking period completed");
        _;
    }
    modifier deadlinePassed(bool requireDeadlinePassed) {
        uint256 timeRemaining = timeLeft();
        if (requireDeadlinePassed) {
            require(timeRemaining <= 0, "Deadline has not been passed yet");
        } else {
            require(timeRemaining > 0, "Deadline is already passed");
        }
        _;
    }

    // Bools
    bool public openForWithdraw;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    function stake() public payable deadlinePassed(false) notCompleted {
        balances[msg.sender] = balances[msg.sender] + msg.value;
        emit Stake(msg.sender, msg.value);
    }

    function execute() public notCompleted {
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
        }
    }

    // if the `threshold` was not met, allow everyone to call a `withdraw()` function
    function withdraw() external deadlinePassed(true) notCompleted {
        require(openForWithdraw, "Not available to withdraw");
        uint256 userBalance = balances[msg.sender];
        require(userBalance > 0, "userBalance is 0");
        //balances = 0 BEFORE sending transaction otherwise vulnerable to reentrancy
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: userBalance}("");
        // checks if the transfer was successful
        require(success, "Failed to send to address");
    }

    // Add a `withdraw()` function to let users withdraw their balance

    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    receive() external payable {
        stake();
    }
}
