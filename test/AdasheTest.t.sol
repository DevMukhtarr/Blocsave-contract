// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Adashe} from "src/Adashe.sol";

contract AdasheTest is Test {
    Adashe adashe;
    IERC20 usdc;

    address owner = address(0xA);
    address alice = address(0xB);
    address bob = address(0xC);
    address carol = address(0xD);

    MockUSDC mockUSDC;

    function setUp() public {
        mockUSDC = new MockUSDC();
        usdc = IERC20(address(mockUSDC));

        // Mint initial balances to users
        mockUSDC.mint(alice, 1000e6);
        mockUSDC.mint(bob, 1000e6);
        mockUSDC.mint(carol, 1000e6);

        vm.prank(owner);
        adashe = new Adashe(owner, address(mockUSDC));

        vm.prank(alice);
        adashe.createAdashe("Weekly Circle", 100e6, 3, "weekly", "alice");

        // Join members
        // vm.prank(alice);
        // adashe.joinAdashe("Alice");

        vm.prank(bob);
        adashe.joinAdashe("Bob");

        vm.prank(carol);
        adashe.joinAdashe("Carol");
    }

    function testFullRound() public {
        // Simulate week 0 contributions
        uint256 startTime = block.timestamp;
        contributeForWeek(0);

        // Set block time to end of week 0
        vm.warp(startTime);

        // Alice should withdraw for week 0
        vm.prank(adressees()[0]);
        adashe.withdraw();

        // Week 1
        contributeForWeek(1);
        vm.warp(startTime + 1 weeks);
        vm.prank(adressees()[1]);
        adashe.withdraw();

        // Week 2
        contributeForWeek(2);
        vm.warp(startTime + 2 weeks);
        vm.prank(adressees()[2]);
        adashe.withdraw();
    }

    function contributeForWeek(uint256 weekNumber) internal {
        for (uint i = 0; i < 3; i++) {
            address member = adressees()[i];
            vm.prank(member);
            usdc.approve(address(adashe), 100e6);

            vm.prank(member);
            adashe.contribute(weekNumber, 100e6);
        }
    }

    function adressees() internal pure returns (address[] memory) {
        address[] memory addrs = new address[](3);
        addrs[0] = address(0xB); // Alice
        addrs[1] = address(0xC); // Bob
        addrs[2] = address(0xD); // Carol
        return addrs;
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
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient");
        require(allowance[from][msg.sender] >= amount, "Not allowed");
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
