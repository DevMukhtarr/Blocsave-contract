// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "./Adashe.sol";

contract AdasheFactory {
    address public owner;
    address constant USDC_ADDRESS = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    mapping (address => address[]) public adashes;
    address[] public allAdashes;
    constructor() {
        owner = msg.sender;
    }

    function createAdashe() external returns (address) {

        Adashe adashe = new Adashe(owner, USDC_ADDRESS);
        address adasheAddress = address(adashe);

        adashes[msg.sender].push(address(adashe));
        allAdashes.push(adasheAddress);

        return adasheAddress;
    }

    function getAdashes() external view returns (address[] memory) {
        return adashes[msg.sender];
    }

     function getActiveCircle() external view returns (address[] memory) {
        address[] memory activeCircles = new address[](allAdashes.length);
        uint256 count = 0;

        for (uint256 i = 0; i < allAdashes.length; i++) {
            Adashe adashe = Adashe(payable(allAdashes[i]));
            address[] memory members = adashe.getMembers();

            for (uint256 j = 0; j < members.length; j++) {
                if (members[j] == msg.sender) {
                    activeCircles[count] = allAdashes[i];
                    count++;
                    break;
                }
            }
        }

        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeCircles[i];
        }

        return result;
    }
}
