// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Contract1} from "../src/Contract1.sol";

contract Contract1Test is Test {
    Contract1 public contract1;

    address alice;
    address bob;
    address charlie;

    function setUp() public {
        //init accounts
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        vm.prank(bob);
        contract1 = new Contract1("MyToken", "MTK");
    }

    function test_bannableTransfer() public {
        // Bob (contract owner) can send alice funds
        vm.prank(bob);
        contract1.bannableTransfer(alice, 1000);
        assertEq(contract1.balanceOf(alice), 1000);
    }

    function test_banningOnBannableTransfer() public {
        // Bob (contract owner) will ban alice and expect revert
        vm.startPrank(bob);
        contract1.banAddress(alice);

        vm.expectRevert();
        contract1.bannableTransfer(alice, 1000);

        // Bob (contract owner) will now unban alice and send funds
        contract1.unbanAddress(alice);
        contract1.bannableTransfer(alice, 1000);
        assertEq(contract1.balanceOf(alice), 1000);
    }
}
