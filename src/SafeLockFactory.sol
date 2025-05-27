// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "./SafeLock.sol";

contract SafeLockFactory {
    address public owner;
    address constant USDC_ADDRESS = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

    mapping (address => address[]) public safelocks;

    constructor() {
        owner = msg.sender;
    }

    function createSafeLock(uint32 _days_in_number) external returns (address) {
        require(_days_in_number == 30 || _days_in_number == 60 || _days_in_number == 90, "Invalid days");

        uint256 lockPeriodDays = _days_in_number * 1 days;

        SafeLock safeLock = new SafeLock(owner, msg.sender,lockPeriodDays, USDC_ADDRESS);

        safelocks[msg.sender].push(address(safeLock));

        return address(safeLock);
    }

    function getSafeLocks() external view returns (address[] memory) {
        return safelocks[msg.sender];
    }

}
