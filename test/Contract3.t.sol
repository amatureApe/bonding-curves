// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Contract3} from "../src/Contract3.sol";

contract Contract3Test is Test {
    Contract3 public contract3;

    address alice;
    address bob;
    address charlie;

    function setUp() public {
        //init accounts
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        vm.prank(bob);
        contract3 = new Contract3();
    }

    function test_buyTokens() public {
        // Mint bob some ether and then buy 1 token. *Sending excess ether*
        vm.deal(bob, 10 ether);

        vm.prank(bob);
        contract3.buyTokens{value: 10 ether}(1);
        assertEq(contract3.balanceOf(bob), 2);
    }

    function testFail_notEnoughEthSent_buyTokens() public {
        // Mint bob some ether and then attempt to buy 1 token. *insufficient ether*
        vm.deal(bob, 10 ether);

        vm.prank(bob);
        contract3.buyTokens{value: 1 ether}(1);
        assertEq(contract3.balanceOf(bob), 2);
    }

    function test_sellTokens() public {
        // First mint ether and buy token
        vm.deal(bob, 10 ether);

        vm.startPrank(bob);
        contract3.buyTokens{value: 10 ether}(5);
        assertEq(contract3.balanceOf(bob), 6);

        // Then sell ether
        contract3.sellTokens(1);
        assertEq(contract3.balanceOf(bob), 5);
    }
}
