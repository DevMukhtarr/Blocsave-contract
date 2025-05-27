// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Adashe} from "src/Adashe.sol";

contract AdasheRandomizedTest is Test {
    Adashe adashe;
    MockUSDC mockUSDC;

    address owner = address(0xA);
    address alice = address(0xB);
    address bob = address(0xC);
    address carol = address(0xD);

    address[] randomizedMembers;
    uint256 constant CONTRIBUTION_AMOUNT = 100e6;

    function setUp() public {
        // Deploy mock token and mint to users
        mockUSDC = new MockUSDC();
        mockUSDC.mint(alice, 1000e6);
        mockUSDC.mint(bob, 1000e6);
        mockUSDC.mint(carol, 1000e6);

        // Deploy Adashe
        vm.prank(owner);
        adashe = new Adashe(owner, address(mockUSDC));

        // Create group with alice
        vm.prank(alice);
        adashe.createAdashe("Weekly Circle", CONTRIBUTION_AMOUNT, 3, "weekly", "Alice");

        // Join members - this will trigger shuffle when carol joins (3rd member)
        vm.prank(bob);
        adashe.joinAdashe("Bob");

        vm.prank(carol);
        adashe.joinAdashe("Carol");

        // Now get the randomized order (shuffle happened when carol joined)
        randomizedMembers = adashe.getRandomizedMembers();
        
        console.log("Randomized withdrawal order:");
        for (uint i = 0; i < randomizedMembers.length; i++) {
            string memory memberName = getMemberName(randomizedMembers[i]);
            // console.log("Week", i, ":", memberName, randomizedMembers[i]);
        }
    }

    function testFullRandomizedRound() public {
        uint256 startTime = block.timestamp;
        
        // Test each week in the randomized order
        for (uint256 week = 0; week < 3; week++) {
            console.log("\n=== WEEK", week, "===");
            console.log("Current timestamp:", block.timestamp);
            console.log("Current week from contract:", adashe.getCurrentWeek());
            
            // All members contribute for this week
            contributeForWeek(week);
            
            // Move to the correct time for this week's withdrawal
            // The contract checks getCurrentWeek() which should match the week we're processing
            uint256 targetTime = startTime + week * 1 weeks + 1; // Add 1 second to ensure we're in the right week
            vm.warp(targetTime);
            
            console.log("Warped to timestamp:", block.timestamp);
            console.log("Current week after warp:", adashe.getCurrentWeek());
            
            // Verify we're in the correct week
            assertEq(adashe.getCurrentWeek(), week, "Should be in the correct week");
            
            // Get the eligible withdrawer for this week
            address eligibleWithdrawer = randomizedMembers[week];
            string memory withdrawerName = getMemberName(eligibleWithdrawer);
            
            // console.log("Eligible withdrawer for week", week, ":", withdrawerName, eligibleWithdrawer);
            
            // Check balance before withdrawal
            uint256 balanceBefore = mockUSDC.balanceOf(eligibleWithdrawer);
            console.log("Balance before withdrawal:", balanceBefore);
            
            // Perform withdrawal
            vm.prank(eligibleWithdrawer);
            adashe.withdraw();
            
            // Check balance after withdrawal
            uint256 balanceAfter = mockUSDC.balanceOf(eligibleWithdrawer);
            uint256 expectedAmount = CONTRIBUTION_AMOUNT * 3; // 3 members
            
            console.log("Balance after withdrawal:", balanceAfter);
            console.log("Amount withdrawn:", balanceAfter - balanceBefore);
            
            // Assertions
            assertEq(balanceAfter - balanceBefore, expectedAmount, "Incorrect withdrawal amount");
        }
        
        console.log("\n=== FULL ROUND COMPLETED SUCCESSFULLY ===");
    }

    function testInvalidWithdrawals() public {
        uint256 startTime = block.timestamp;
        
        // Contribute for week 0
        contributeForWeek(0);
        
        // Stay in week 0 for the withdrawal test
        console.log("Current week:", adashe.getCurrentWeek());
        
        // Try to withdraw with wrong person (should fail)
        address wrongPerson = getWrongPerson(0);
        string memory wrongPersonName = getMemberName(wrongPerson);
        string memory correctPersonName = getMemberName(randomizedMembers[0]);
        
        console.log("Trying to withdraw with wrong person:", wrongPersonName);
        console.log("Correct person should be:", correctPersonName);
        
        vm.prank(wrongPerson);
        vm.expectRevert(Adashe.NotEligibleToWithdraw.selector);
        adashe.withdraw();
        
        // Correct person withdraws successfully
        vm.prank(randomizedMembers[0]);
        adashe.withdraw();
        
        // Try to withdraw again with same person (double withdrawal - should fail)
        vm.prank(randomizedMembers[0]);
        vm.expectRevert(Adashe.AlreadyWithdrawn.selector);
        adashe.withdraw();
        
        console.log("Invalid withdrawal tests passed");
    }

    function testContributionTracking() public {
        // Test contribution tracking
        contributeForWeek(0);
        
        for (uint i = 0; i < randomizedMembers.length; i++) {
            address member = randomizedMembers[i];
            (uint256 contributedWeeks, uint256 totalWeeks) = adashe.getContributionProgress(member);
            assertEq(contributedWeeks, 1, "Should have contributed 1 week");
            assertEq(totalWeeks, 3, "Total weeks should be 3");
        }
    }

    function testCurrentWeekCalculation() public {
        uint256 startTime = block.timestamp;
        
        // At start
        assertEq(adashe.getCurrentWeek(), 0, "Should be week 0 at start");
        
        // After 1 week
        vm.warp(startTime + 1 weeks);
        assertEq(adashe.getCurrentWeek(), 1, "Should be week 1 after 1 week");
        
        // After 2 weeks
        vm.warp(startTime + 2 weeks);
        assertEq(adashe.getCurrentWeek(), 2, "Should be week 2 after 2 weeks");
    }

    function testDebugTiming() public {
        uint256 startTime = block.timestamp;
        console.log("Contract start time:", startTime);
        console.log("Initial current week:", adashe.getCurrentWeek());
        
        // Test timing for each week
        for (uint256 i = 0; i < 4; i++) {
            uint256 targetTime = startTime + i * 1 weeks;
            vm.warp(targetTime);
            console.log("Time:", targetTime, "Week:", adashe.getCurrentWeek());
        }
    }

    function contributeForWeek(uint256 weekNumber) internal {
        console.log("Contributing for week", weekNumber);
        
        for (uint i = 0; i < randomizedMembers.length; i++) {
            address member = randomizedMembers[i];
            string memory memberName = getMemberName(member);
            
            // Approve and contribute
            vm.prank(member);
            mockUSDC.approve(address(adashe), CONTRIBUTION_AMOUNT);
            
            vm.prank(member);
            adashe.contribute(weekNumber, CONTRIBUTION_AMOUNT);
            
            // console.log(memberName, "contributed", CONTRIBUTION_AMOUNT, "for week", weekNumber);
        }
    }

    function getMemberName(address member) internal view returns (string memory) {
        if (member == alice) return "Alice";
        if (member == bob) return "Bob";
        if (member == carol) return "Carol";
        return "Unknown";
    }

    function getWrongPerson(uint256 weekIndex) internal view returns (address) {
        // Return someone who is NOT eligible for this week
        for (uint i = 0; i < randomizedMembers.length; i++) {
            if (randomizedMembers[i] != randomizedMembers[weekIndex]) {
                return randomizedMembers[i];
            }
        }
        return randomizedMembers[0]; // fallback
    }

    // Test multiple scenarios with different random seeds
    function testMultipleRandomScenarios() public {
        // This test demonstrates that the randomization works across different deployments
        for (uint256 seed = 0; seed < 3; seed++) {
            console.log("\n=== Testing scenario", seed, "===");
            
            // Create new deployment with different timestamp (affects randomization)
            vm.warp(block.timestamp + seed * 100);
            
            MockUSDC newMockUSDC = new MockUSDC();
            newMockUSDC.mint(alice, 1000e6);
            newMockUSDC.mint(bob, 1000e6);
            newMockUSDC.mint(carol, 1000e6);

            vm.prank(owner);
            Adashe newAdashe = new Adashe(owner, address(newMockUSDC));

            vm.prank(alice);
            newAdashe.createAdashe("Test Circle", CONTRIBUTION_AMOUNT, 3, "weekly", "Alice");

            vm.prank(bob);
            newAdashe.joinAdashe("Bob");

            vm.prank(carol);
            newAdashe.joinAdashe("Carol");

            address[] memory newRandomOrder = newAdashe.getRandomizedMembers();
            
            console.log("Random order for scenario", seed, ":");
            for (uint i = 0; i < newRandomOrder.length; i++) {
                console.log("Position", i, ":", getMemberName(newRandomOrder[i]));
            }
        }
    }
}

contract MockUSDC is IERC20 {
    string public constant name = "MockUSDC";
    string public constant symbol = "mUSDC";
    uint8 public constant decimals = 6;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }
}