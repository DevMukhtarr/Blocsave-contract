// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

 struct Saving {
        bytes32 txId;
        uint256 date;
        uint256 amount;
    }

struct Withdrawal {
        bytes32 txId;
        uint256 date;
        uint256 amount;
    }
interface IQuickSave {
    function save(uint256 amount)external payable;
    function withdraw(uint256 amount) external;
    function getSavingHistory(address user) external view returns (Saving[] memory);
    function getWithdrawalHistory(address user) external view returns (Withdrawal[] memory);
    function EmergencyWithdrawal() external;
    function withdrawETH() external;
}