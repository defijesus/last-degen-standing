// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { LastDegenStanding } from "../src/LastDegenStanding.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract LDS_Test is PRBTest, StdCheats {
    LastDegenStanding internal lds;
    address internal bob = address(0xB0B);
    address internal player1 = address(0xB00B);
    address internal player2 = address(0xB00B135);

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        vm.deal(player1, 1 ether);
        vm.deal(player2, 1 ether);
        // Instantiate the contract-under-test.
        vm.prank(bob);
        lds = new LastDegenStanding(1 ether, 500, 500, 500, 100, bob, 500);
        vm.prank(player1);
        lds.join{ value: 1 ether }();
    }

    function test_Join() external {
        vm.prank(player2);
        lds.join{ value: 1 ether }();
        assertEq(lds.ownerOf(1), player2);
    }

    function test_JoinAndTransferToNew() external {
        vm.startPrank(player2);
        lds.join{ value: 1 ether }();
        lds.transferFrom(player2, address(123), 1);
        assertEq(lds.ownerOf(1), address(123));
    }

    function testFail_JoinAndTransferToExisting() external {
        vm.startPrank(player2);
        lds.join{ value: 1 ether }();
        lds.transferFrom(player2, player1, 1);
    }

    function testFail_JoinAfterStart() external {
        vm.prank(bob);
        lds.startGame();
        vm.prank(player2);
        lds.join{ value: 1 ether }();
    }

    function test_Gm() external {
        vm.prank(bob);
        lds.startGame();
        uint256 before = block.timestamp;
        vm.warp(block.timestamp + 10 minutes);
        uint256 afterTime = block.timestamp;
        vm.prank(player1);
        lds.gm(0);
        assertEq(lds.getLastSeen(0), afterTime);
    }

    function test_Delete() external {
        vm.prank(player2);
        lds.join{ value: 1 ether }();
        vm.prank(bob);
        lds.startGame();
        vm.warp(block.timestamp + 48 hours);
        vm.prank(player1);
        uint256[] memory players = new uint256[](1);
        players[0] = 1;
        lds.deletePlayers(players);
    }

    function test_Seppuku() external {
        vm.warp(block.timestamp + 48 hours);
        vm.prank(bob);
        lds.startGame();
        vm.prank(player1);
        lds.seppuku(0);
    }

    function test_Win() external {
        vm.prank(player2);
        lds.join{ value: 1 ether }();
        vm.prank(bob);
        lds.startGame();
        vm.warp(block.timestamp + 48 hours);
        vm.startPrank(player1);
        uint256[] memory players = new uint256[](1);
        players[0] = 1;
        lds.deletePlayers(players);
        lds.win(0);
        vm.stopPrank();
    }
}
