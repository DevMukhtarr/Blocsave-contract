// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "./Adashe.sol";

contract AdasheFactory {
    address public owner;
    address constant USDC_ADDRESS = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    // address constant USDC_ADDRESS = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    mapping (address => address[]) public adashes;

    constructor() {
        owner = msg.sender;
    }

    function createAdashe() external returns (address) {

        Adashe adashe = new Adashe(msg.sender, USDC_ADDRESS);

        adashes[msg.sender].push(address(adashe));

        return address(adashe);
    }

    function getAdashes() external view returns (address[] memory) {
        return adashes[msg.sender];
    }
}
