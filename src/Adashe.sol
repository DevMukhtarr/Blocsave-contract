// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Adashe {
    IERC20 public usdc;
    address public admin;

     struct AdasheSaving {
        string circleName;
        uint256 weeklyContribution;
        uint256 noOfMembers;
        address[] members;
        bool withdrawn;
        string frequency;
        string creatorName;
    }

    struct WeeklyContribution {
        uint256 amount;
        uint256 timestamp;
        bool paid;
    }

    struct TransactionHistory {
        string transactionType;
        string name;
        address user;
        uint256 week;
        uint256 date;
        uint256 amount;
    }

    error InvalidAmount();
    error InvalidMembers();
    error InvalidWeek();
    error AlreadyAdasheGroupMember();
    error NotEligibleToWithdraw();
    error AlreadyWithdrawn();
    error AlreadyPaidThisWeek();
    error InvalidLockPeriod();
    error TransferFailed();
    error CallerNotAdmin();
    error NotYetUnlocked();
    error GroupIsFull();

    event AdasheDeposit(address user, uint256 amount, uint256 time, uint256 lockPeriod);
    event AdasheCreated(string adashe, string frequency);
    event Withdraw(address user, uint256 amount, uint256 time);
    event EtherWithdrawn(address indexed to, uint256 amount, uint256 timestamp);
    event JoinedAdashe(address user);

    mapping(address => uint256) totalDeposited;
    mapping(address => bool) hasJoined;
    mapping(address => bool) hasContributed;
    mapping(address => mapping(uint256 => WeeklyContribution)) public contributions;
    mapping(address => string) public names;
    mapping(address => uint256) public weeksContributed;
    mapping(address => TransactionHistory[]) public transactions;
    mapping(address => bool[]) public memberWeekWithdrawals;

    AdasheSaving public adashe;
    uint256 public totalPot;
    uint256 public totalWeeks;
    uint256 public immutable startDate;
    uint256 public frequency;

    address[] public randomizedMembers;
    bool public isShuffled;
    
    constructor(address _admin, address _usdc) {
        usdc = IERC20(_usdc);
        admin = _admin;
        startDate = block.timestamp;
        frequency = 604800;
    }

    modifier onlyAdmin {
        if(msg.sender != admin){
         revert CallerNotAdmin();
        }
        _;
    }

    modifier NotAlreadyMember() {
        if (hasJoined[msg.sender]) revert AlreadyAdasheGroupMember();
        _;
    }

    uint256 public totalSaving;

    function createAdashe(
        string memory _circleName,
        uint256 _weeklyContribution,
        uint256 _noOfMembers,
        string memory _frequency,
        string memory _creatorName
    ) external {
        if (_noOfMembers == 0) revert InvalidMembers();
        if (_weeklyContribution == 0) revert InvalidAmount();

          address[] memory initialMembers = new address[](0);

        adashe = AdasheSaving({
            circleName: _circleName,
            weeklyContribution: _weeklyContribution,
            noOfMembers: _noOfMembers,
            members: initialMembers,
            withdrawn: false,
            frequency: _frequency,
            creatorName: _creatorName
        });

        adashe.members.push(msg.sender);
        names[msg.sender] = _creatorName;
        hasJoined[msg.sender] = true;

        memberWeekWithdrawals[msg.sender] = new bool[](adashe.noOfMembers);

        if (keccak256(bytes(_frequency)) == keccak256(bytes("weekly"))) {
        frequency = 1 weeks;
        } else if (keccak256(bytes(_frequency)) == keccak256(bytes("monthly"))) {
        frequency = 30 days;
        } else if (keccak256(bytes(_frequency)) == keccak256(bytes("daily"))) {
        frequency = 1 days;
        } else {
        frequency = 1 weeks;
        }

        totalWeeks = _noOfMembers;

        emit AdasheCreated(_circleName, _frequency);
    }

    function shuffleMembers() internal {
    require(adashe.members.length == adashe.noOfMembers, "Group not full");
    require(!isShuffled, "Already shuffled");

    randomizedMembers = adashe.members;

    for (uint256 i = 0; i < randomizedMembers.length; i++) {
        uint256 j = i + uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, i))) % (randomizedMembers.length - i);
        address temp = randomizedMembers[i];
        randomizedMembers[i] = randomizedMembers[j];
        randomizedMembers[j] = temp;
    }

    isShuffled = true;
    }

    function joinAdashe (string memory _name) external NotAlreadyMember {
        if(adashe.members.length >= adashe.noOfMembers) revert GroupIsFull();

        adashe.members.push(msg.sender);
        names[msg.sender] = _name;
        hasJoined[msg.sender] = true;

        memberWeekWithdrawals[msg.sender] = new bool[](adashe.noOfMembers);

        emit JoinedAdashe(msg.sender);
        if (adashe.members.length == adashe.noOfMembers && !isShuffled) {
        shuffleMembers();
        }
    }
    
    function contribute (uint256 weekNumber, uint256 _amount) external {
         if (weekNumber > totalWeeks) revert InvalidWeek();
         if (contributions[msg.sender][weekNumber].paid) revert AlreadyPaidThisWeek();
         if (_amount != adashe.weeklyContribution) revert InvalidAmount();

         bool success = usdc.transferFrom(msg.sender, address(this), _amount);
         if (!success) revert TransferFailed();

         contributions[msg.sender][weekNumber] = WeeklyContribution({
            amount: _amount,
            timestamp: block.timestamp,
            paid: true
        });

         transactions[msg.sender].push(TransactionHistory({
            transactionType: "Contribute",
            name: names[msg.sender],
            user: msg.sender,
            week: weekNumber,
            date: block.timestamp,
            amount: _amount
        }));

        hasContributed[msg.sender] = true;
        weeksContributed[msg.sender] += 1;
    }

   function withdraw() external {
    uint256 currentWeek = getCurrentWeek();
    if (!isShuffled) revert("Withdrawals not yet allowed; group not full");
    if (currentWeek >= adashe.members.length) revert InvalidWeek();
    address eligible = randomizedMembers[currentWeek];

    if (msg.sender != eligible) revert NotEligibleToWithdraw();

    if (memberWeekWithdrawals[msg.sender][currentWeek]) revert AlreadyWithdrawn();

    memberWeekWithdrawals[msg.sender][currentWeek] = true;

    uint256 totalAmount = adashe.weeklyContribution * adashe.noOfMembers;

    if (!usdc.transfer(msg.sender, totalAmount)) revert TransferFailed();

    transactions[msg.sender].push(TransactionHistory({
            transactionType: "Withdraw",
            name: names[msg.sender],
            user: msg.sender,
            week: currentWeek,
            date: block.timestamp,
            amount: totalAmount
        }));

    emit Withdraw(msg.sender, totalAmount, block.timestamp);
    }

    function getMembers() external view returns (address[] memory) {
        return adashe.members;
    }

    function getContributionProgress(address user) external view returns (uint256 contributedWeeks, uint256 total) {
    return (weeksContributed[user], totalWeeks);
    }

    function getCurrentWeek() public view returns (uint256) {
    if (block.timestamp < startDate) {
        return 0;
    }
    return (block.timestamp - startDate) / frequency;
    }

    function getRandomizedMembers() external view returns (address[] memory) {
    return randomizedMembers;
    }

    function getTransactionHistory() external view returns (TransactionHistory[] memory){
        return transactions[msg.sender];
    }

    function getUserTransactionHistory(address user) external view onlyAdmin returns (TransactionHistory[] memory) {
    return transactions[user];
}

     receive() external payable{}
}