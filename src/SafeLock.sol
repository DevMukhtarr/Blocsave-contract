// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SafeLock {
    IERC20 public usdc;

    address public owner;
    address public user;
    uint256 public immutable LOCK_PERIOD;
    uint256 public totalDeposited;

    // errors
    error InvalidAmount();
    error AlreadyWithdrawn();
    error InvalidLockPeriod();
    error TransferFailed();
    error CallerNotOwner();
    error CallerNotUser();
    error NotYetUnlocked();

    // events
    event LockedDeposit(address user, uint256 amount, uint256 time, uint256 lockPeriod);
    event Withdraw(address user, uint256 amount, uint256 time);
    event EmergencyWithdrawalExecuted(address indexed owner, uint256 amount, uint256 timestamp);
    event EtherWithdrawn(address indexed to, uint256 amount, uint256 timestamp);
    event SupplySuccessful(address user);
    constructor(address _owner, address _user,uint256 _lockPeriod, address _usdc) {
        usdc = IERC20(_usdc);
        owner = _owner;
        user = _user;
        LOCK_PERIOD = block.timestamp + _lockPeriod;
    }

     modifier onlyOwner {
        if(msg.sender != owner){
         revert CallerNotOwner();
        }
        _;
    }

    modifier onlyUser() {
    if (msg.sender != user) {
        revert CallerNotUser();
    }
    _;
}

    struct LockedSaving {
        bytes32 txId;
        uint256 date;
        uint256 amount;
        bool withdrawn;
        uint256 lockPeriod;
        uint256 daysPassed;
    }

    struct Withdrawal {
        bytes32 txId;
        uint256 date;
        uint256 amount;
        uint256 lockPeriod;
    }
    struct EmergencyWithdrawalStruct {
        bytes32 txId;
        uint256 date;
        uint256 amount;
    }

     mapping (address => LockedSaving[]) public lockedSavingHistory;
     mapping (address => uint256) public userBalance;
     mapping (address => Withdrawal[]) public withdrawalHistory;
     mapping (address => EmergencyWithdrawalStruct[]) public emergencyWithdrawalHistory;

    function deposit(uint256 amount) external onlyUser{
        if (amount == 0) revert InvalidAmount();

        bool success = usdc.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed();

        userBalance[msg.sender] += amount;
        totalDeposited += amount;

        lockedSavingHistory[msg.sender].push(LockedSaving({
            txId: keccak256(abi.encodePacked(msg.sender, amount, block.timestamp)),
            date: block.timestamp,
            amount: amount,
            withdrawn: false,
            lockPeriod: LOCK_PERIOD,
            daysPassed: 0
        }));

        emit LockedDeposit(msg.sender, amount, block.timestamp, LOCK_PERIOD);
    }

    function withdraw(uint256 index) external onlyUser{
        LockedSaving storage saving = lockedSavingHistory[msg.sender][index];

        if (saving.amount == 0) revert InvalidAmount();
        if (userBalance[msg.sender] < saving.amount) revert InvalidAmount();
        if (block.timestamp < saving.lockPeriod) revert NotYetUnlocked();
        if (saving.withdrawn) revert AlreadyWithdrawn();

        // withdrawing to compound should be here
      
        userBalance[msg.sender] -= saving.amount;
        bool success = usdc.transfer(msg.sender, saving.amount);
        if (!success) revert TransferFailed();

        uint256 daysPassed;
        (daysPassed,,) = getLockedProgress(index);

        saving.withdrawn = true;
        saving.daysPassed = daysPassed;

        emit Withdraw(msg.sender, saving.amount, block.timestamp);
    }

    function getLockedSaving() external view returns (LockedSaving[] memory){
        return lockedSavingHistory[user];
    }

    function getWithdrawalHistory() external view returns (Withdrawal[] memory) {
    return withdrawalHistory[user];
    }

    function EmergencyWithdrawal() external onlyOwner{
        // checks USDC balance
        uint256 usdcBalance = usdc.balanceOf(address(this));

        // transfers USDC to owner
        bool success = usdc.transfer(msg.sender, usdcBalance);
        if (!success) revert TransferFailed();

        emergencyWithdrawalHistory[msg.sender].push(EmergencyWithdrawalStruct({
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

    function getLockedProgress(uint index) public view returns (uint256 daysPassed, uint256 totalDays, uint256 daysRemaining) {
    LockedSaving memory saving = lockedSavingHistory[user][index];

    // Total duration in seconds
    uint256 totalDuration = saving.lockPeriod - saving.date;
    totalDays = totalDuration / 1 days;

    // Time elapsed in seconds
    uint256 elapsed = block.timestamp > saving.lockPeriod
        ? totalDuration
        : block.timestamp - saving.date;

    daysPassed = elapsed / 1 days;
    daysRemaining = totalDays > daysPassed ? totalDays - daysPassed : 0;
    }

    receive() external payable{}
}
