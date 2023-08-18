// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { TheLastDegenStanding } from "../src/TheLastDegenStanding.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract LDS_Test is PRBTest, StdCheats {
    TheLastDegenStanding internal lds;
    address internal admin = address(0xB0B);
    address internal player1 = address(0xB00B);
    address internal player2 = address(0xB00B13);
    address internal player3 = address(0xB00B135);
    uint256 internal ticketPrice;

    function setUp() public virtual {
        vm.deal(player1, 1 ether);
        vm.deal(player2, 1 ether);
        lds = new TheLastDegenStanding();
        ticketPrice = lds.$TICKET_PRICE();
    }

    function test_Join() external {
        vm.prank(player1);
        lds.join{ value: ticketPrice }();
        assertEq(lds.ownerOf(0), player1);
    }


    function test_JoinAndTransferToNew() external {
        vm.startPrank(player1);
        lds.join{ value: ticketPrice }();
        lds.transferFrom(player1, player2, 0);
        assertEq(lds.ownerOf(0), player2);
    }

    function testFail_JoinAndTransferToExisting() external {
        startGameWithPlayers();
        lds.transferFrom(player2, player1, 1);
    }

    function testFail_JoinMultipleTimes() external {
        startGameWithPlayers();
        vm.prank(player1);
        lds.join{ value: ticketPrice }();
    }

    function testFail_JoinAfterStart() external {
        startGameWithPlayers();
        vm.prank(player3);
        lds.join{ value: ticketPrice }();
    }

    function test_Gm() external {
        startGameWithPlayers();
        vm.warp(block.timestamp + 10 minutes);
        uint256 afterTime = block.timestamp;
        vm.prank(player1);
        lds.gm(0);
        assertEq(lds.getLastSeen(0), afterTime);
    }

    function test_GmForFren() external {
        startGameWithPlayers();
        vm.warp(block.timestamp + 10 minutes);
        uint256 afterTime = block.timestamp;
        vm.prank(player1);
        lds.gm(1);
        assertEq(lds.getLastSeen(1), afterTime);
    }

    function test_Delete() external {
        startGameWithPlayers();
        vm.warp(block.timestamp + 48 hours);
        vm.prank(player1);
        uint256[] memory players = new uint256[](1);
        players[0] = 1;
        lds.deleteDegens(players);
    }

    function test_Seppuku() external {
        startGameWithPlayers();
        vm.warp(block.timestamp + 48 hours);
        vm.prank(player1);
        lds.seppuku(0);
    }

    function test_Win() external {
        startGameWithPlayers();
        vm.warp(block.timestamp + 48 hours);
        vm.startPrank(player1);
        uint256[] memory players = new uint256[](1);
        players[0] = 1;
        lds.deleteDegens(players);
        lds.win(0);
        vm.stopPrank();
    }

    function startGameWithPlayers() internal {
        vm.prank(player1);
        lds.join{ value: ticketPrice }();
        vm.prank(player2);
        lds.join{ value: ticketPrice }();
        vm.warp(block.timestamp + 25 hours);
        lds.startGame();
    }
}
