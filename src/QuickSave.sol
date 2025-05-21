// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract QuickSave {
IERC20 public usdc;

    error InvalidAmount();
    error TransferFailed();
    error CallerNotOwner();

    event Saved(address user, uint256 amount, uint256 time);
    event Withdraw(address user, uint256 amount, uint256 time);
    event EmergencyWithdrawalExecuted(address indexed owner, uint256 amount, uint256 timestamp);
    event EtherWithdrawn(address indexed to, uint256 amount, uint256 timestamp);

    address public owner;
    constructor(address _usdc) {
        usdc = IERC20(_usdc);
        owner = msg.sender;
    }

    modifier onlyOwner {
        if(msg.sender != owner){
         revert CallerNotOwner();
        }
        _;
    }


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

    mapping (address => Saving[]) public savingHistory;
    mapping (address => Withdrawal[]) public withdrawalHistory;
    mapping (address => uint256) public balances;

    function save(uint256 amount)external payable{
        if(amount == 0){
            revert InvalidAmount();
        }

         bool success = usdc.transferFrom(msg.sender, address(this), amount);
         if (!success) revert TransferFailed();

        balances[msg.sender] += amount;
        savingHistory[msg.sender].push(Saving({
            amount: amount,
            date: block.timestamp,
            txId: keccak256(abi.encodePacked(msg.sender, amount, block.timestamp))
        }));

        emit Saved(msg.sender, amount, block.timestamp);
    } 

    function withdraw(uint256 amount) external {
        // checks if amount is valid
        if (amount == 0) revert InvalidAmount();
        if (amount > balances[msg.sender]) revert InvalidAmount();

        // deduct from user balance and transfer
        balances[msg.sender] -= amount;
        bool success = usdc.transfer(msg.sender, amount);
        if (!success) revert TransferFailed();

        withdrawalHistory[msg.sender].push(Withdrawal({
            txId: keccak256(abi.encodePacked(msg.sender, amount, block.timestamp)),
            date: block.timestamp,
            amount: amount
        }));

        emit Withdraw(msg.sender, amount, block.timestamp);
    }

    function getSavingHistory(address user) external view returns (Saving[] memory){
        return savingHistory[user];
    }

    function getWithdrawalHistory(address user) external view returns (Withdrawal[] memory) {
    return withdrawalHistory[user];
    }

    function EmergencyWithdrawal() external onlyOwner{
        // checks USDC balance
        uint256 usdcBalance = usdc.balanceOf(address(this));

        // transfers USDC to owner
        bool success = usdc.transfer(msg.sender, usdcBalance);
        if (!success) revert TransferFailed();

        withdrawalHistory[msg.sender].push(Withdrawal({
        txId: keccak256(abi.encodePacked(msg.sender, usdcBalance, block.timestamp)),
        amount: usdcBalance,
        date: block.timestamp
        }));

        emit EmergencyWithdrawalExecuted(owner, usdcBalance, block.timestamp);
    }

    function withdrawETH() external onlyOwner {
    uint256 balance = address(this).balance;

    (bool success, ) = payable(msg.sender).call{value: balance}("");
    if (!success) revert TransferFailed();

    emit EtherWithdrawn(msg.sender, balance, block.timestamp);
    }
    receive() external payable{}
}