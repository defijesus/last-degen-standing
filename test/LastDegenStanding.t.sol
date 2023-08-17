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
        lds.join{value: 1 ether}();
    }

    function test_Join() external {
        vm.prank(player2);
        lds.join{value: 1 ether}();
        assertEq(lds.ownerOf(1), player2);
    }

    function testFail_JoinAfterStart() external {
        vm.prank(bob);
        lds.startGame();
        vm.prank(player2);
        lds.join{value: 1 ether}();
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
        lds.join{value: 1 ether}();
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
        lds.join{value: 1 ether}();
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

    // /// @dev Basic test. Run it with `forge test -vvv` to see the console log.
    // function test_Example() external {
    //     console2.log("Hello World");
    //     uint256 x = 42;
    //     assertEq(foo.id(x), x, "value mismatch");
    // }

    // /// @dev Fuzz test that provides random values for an unsigned integer, but which rejects zero as an input.
    // /// If you need more sophisticated input validation, you should use the `bound` utility instead.
    // /// See https://twitter.com/PaulRBerg/status/1622558791685242880
    // function testFuzz_Example(uint256 x) external {
    //     vm.assume(x != 0); // or x = bound(x, 1, 100)
    //     assertEq(foo.id(x), x, "value mismatch");
    // }

    // /// @dev Fork test that runs against an Ethereum Mainnet fork. For this to work, you need to set `API_KEY_ALCHEMY`
    // /// in your environment You can get an API key for free at https://alchemy.com.
    // function testFork_Example() external {
    //     // Silently pass this test if there is no API key.
    //     string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
    //     if (bytes(alchemyApiKey).length == 0) {
    //         return;
    //     }

    //     // Otherwise, run the test against the mainnet fork.
    //     vm.createSelectFork({ urlOrAlias: "mainnet", blockNumber: 16_428_000 });
    //     address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    //     address holder = 0x7713974908Be4BEd47172370115e8b1219F4A5f0;
    //     uint256 actualBalance = IERC20(usdc).balanceOf(holder);
    //     uint256 expectedBalance = 196_307_713.810457e6;
    //     assertEq(actualBalance, expectedBalance);
    // }
}
