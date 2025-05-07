// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Name {
    address public owner;
    constructor() {
        owner = msg.sender;
    }

    error IncorrectAmount();
    error InvalidUser();

    struct Saving {
        bytes32 txId;
        uint256 date;
        uint256 amount;
    }

    mapping (address => Saving[]) public savingHistory;

    function save(uint256 amount)external payable{
        if(amount != msg.value){
            revert IncorrectAmount();
        }
        if(msg.sender == address(0)){
            revert InvalidUser();
        }

    } 
}