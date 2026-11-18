// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {AgenticRoute} from "../src/AgenticRoute.sol";

/// @notice Fork test against the REAL Agent ID registry on BNB Chain mainnet.
///         Run: forge test --match-contract ForkTest --fork-url https://bsc-dataseed.binance.org
contract ForkTest is Test {
    address constant REGISTRY = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;
    address constant BAW = 0x3BF4db18045D495Ad703981677d99CE213972B3D; // holds handle "0xkylian"
    address constant NOBODY = 0x000000000000000000000000000000000000dEaD;

    AgenticRoute route;

    function setUp() public {
        route = new AgenticRoute(REGISTRY);
    }

    function testRealRegistryResolvesKylian() public view {
        assertEq(route.resolve("0xkylian"), BAW);
    }

    function testRealHolderCanSendBNB() public {
        vm.deal(BAW, 1 ether);
        uint256 before = BAW.balance;
        vm.prank(BAW);
        route.sendBNB{value: 0.1 ether}("0xkylian"); // sends to itself by name
        assertEq(BAW.balance, before); // -0.1 out, +0.1 in (no gas in prank context)
    }

    function testRealNonHolderReverts() public {
        vm.deal(NOBODY, 1 ether);
        vm.expectRevert(AgenticRoute.NoAgentID.selector);
        vm.prank(NOBODY);
        route.sendBNB{value: 0.1 ether}("0xkylian");
    }
}
