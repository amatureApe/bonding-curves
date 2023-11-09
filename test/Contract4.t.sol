// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Contract1} from "../src/Contract1.sol";
import {Contract4, EscrowData} from "../src/Contract4.sol";

contract Contract4Test is Test {
    Contract1 public myToken;
    Contract4 public contract4;

    address alice;
    address bob;
    address charlie;

    function setUp() public {
        //init accounts
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        vm.startPrank(bob);
        myToken = new Contract1("MyToken", "MTK");
        contract4 = new Contract4();
        vm.stopPrank();
    }

    function test_createEscrow() public {
        // create escrow and check to see if it exists
        vm.startPrank(bob);

        // approve myToken for transfer to escrow contract
        myToken.approve(address(contract4), type(uint256).max);

        contract4.createEscrow(address(alice), address(myToken), 100, 3 days);

        // Check escrow counter
        uint256 bobEscrowCount = contract4.checkEscrowCounterForUser(bob);
        assertEq(bobEscrowCount, 1);

        EscrowData memory escrow = contract4.checkEscrowAtEscrowIdForUser(
            bob,
            0
        );

        assertEq(escrow.seller, alice);
        assertEq(escrow.tokenAddress, address(myToken));
        assertEq(escrow.amount, 100);
        assertGe(escrow.withdrawalTime, 3 days);
    }

    function test_withdrawFunds() public {
        // create escrow and check to see if it exists
        vm.startPrank(bob);

        // approve myToken for transfer to escrow contract
        myToken.approve(address(contract4), type(uint256).max);

        contract4.createEscrow(address(alice), address(myToken), 100, 3 days);
        vm.stopPrank();

        vm.warp(block.timestamp + 3 days);

        vm.prank(alice);
        contract4.withdrawFunds(bob, 0);

        assertEq(myToken.balanceOf(alice), 100);
    }

    function test_recoverFunds() public {
        // create escrow and check to see if it exists
        vm.startPrank(bob);

        // approve myToken for transfer to escrow contract
        myToken.approve(address(contract4), type(uint256).max);

        contract4.createEscrow(address(alice), address(myToken), 100, 3 days);

        vm.warp(block.timestamp + 33 days);

        contract4.recoverTokens(0);
    }
}
