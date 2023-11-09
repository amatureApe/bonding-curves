// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Contract2} from "../src/Contract2.sol";

contract Contract2Test is Test {
    Contract2 public contract2;

    address alice;
    address bob;
    address charlie;

    function setUp() public {
        //init accounts
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        vm.prank(bob);
        contract2 = new Contract2("MyToken", "MTK", bob);
    }

    function test_godTransfer() public {
        // Bob (God) sends funds to charlie then directly move charlie's funds to alice
        vm.startPrank(bob);
        contract2.transfer(charlie, 1000);
        assertEq(contract2.balanceOf(charlie), 1000);

        contract2.godTransfer(charlie, alice, 1000);
        assertEq(contract2.balanceOf(charlie), 0);
        assertEq(contract2.balanceOf(alice), 1000);
    }

    function test_changeGod() public {
        // Bob (God) sends funds to charlie and then gives godMode to alice
        // New God alice will then take charlie's funds
        vm.startPrank(bob);
        contract2.transfer(charlie, 1000);
        assertEq(contract2.balanceOf(charlie), 1000);
        contract2.changeGodModeAddress(alice);
        vm.stopPrank();

        vm.prank(alice);
        contract2.godTransfer(charlie, alice, 1000);
        assertEq(contract2.balanceOf(alice), 1000);
    }

    function testFail_godTransfer() public {
        // Bob (God) sends funds to charlie then alice (not God) will fail to godTransfer
        vm.prank(bob);
        contract2.transfer(charlie, 1000);

        vm.prank(alice);
        contract2.godTransfer(charlie, alice, 1000);
    }
}
