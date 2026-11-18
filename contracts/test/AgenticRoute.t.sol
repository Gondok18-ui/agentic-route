// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {AgenticRoute} from "../src/AgenticRoute.sol";

contract MockRegistry {
    mapping(address => uint256) public balanceOf;
    mapping(bytes32 => address) private _owners;

    function setHolder(address who, uint256 n) external {
        balanceOf[who] = n;
    }

    function setHandle(string calldata handle, address owner) external {
        _owners[keccak256(bytes(handle))] = owner;
    }

    function ownerOfHandle(string calldata handle) external view returns (address) {
        return _owners[keccak256(bytes(handle))];
    }
}

contract MockERC20 {
    string public name = "Mock";
    uint8 public decimals = 18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(allowance[from][msg.sender] >= amount, "allowance");
        require(balanceOf[from] >= amount, "balance");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract RejectingReceiver {
    receive() external payable {
        revert("no thanks");
    }
}

contract AgenticRouteTest is Test {
    MockRegistry registry;
    MockERC20 token;
    AgenticRoute route;

    address holder = address(0xA11CE);
    address stranger = address(0xBAD);
    address alice = address(0xA11C3);
    address bob = address(0xB0B);

    event NameSent(address indexed from, address indexed to, string handle, address token, uint256 amount);

    function setUp() public {
        registry = new MockRegistry();
        token = new MockERC20();
        route = new AgenticRoute(address(registry));

        registry.setHolder(holder, 1);
        registry.setHandle("alice", alice);
        registry.setHandle("bob", bob);

        vm.deal(holder, 10 ether);
        vm.deal(stranger, 10 ether);
        token.mint(holder, 1_000 ether);
    }

    function testResolveReturnsOwner() public view {
        assertEq(route.resolve("alice"), alice);
    }

    function testResolveUnknownReverts() public {
        vm.expectRevert(AgenticRoute.NameNotFound.selector);
        route.resolve("ghost");
    }

    function testSendBNB() public {
        uint256 before = alice.balance;
        vm.expectEmit(true, true, false, true);
        emit NameSent(holder, alice, "alice", address(0), 1 ether);
        vm.prank(holder);
        route.sendBNB{value: 1 ether}("alice");
        assertEq(alice.balance, before + 1 ether);
    }

    function testSendBNBNonHolderReverts() public {
        vm.expectRevert(AgenticRoute.NoAgentID.selector);
        vm.prank(stranger);
        route.sendBNB{value: 1 ether}("alice");
    }

    function testSendBNBUnknownNameReverts() public {
        vm.expectRevert(AgenticRoute.NameNotFound.selector);
        vm.prank(holder);
        route.sendBNB{value: 1 ether}("ghost");
    }

    function testSendBNBZeroValueReverts() public {
        vm.expectRevert(AgenticRoute.ZeroAmount.selector);
        vm.prank(holder);
        route.sendBNB{value: 0}("alice");
    }

    function testSendBNBToRejectingContractReverts() public {
        RejectingReceiver rr = new RejectingReceiver();
        registry.setHandle("vault", address(rr));
        vm.expectRevert(AgenticRoute.TransferFailed.selector);
        vm.prank(holder);
        route.sendBNB{value: 1 ether}("vault");
    }

    function testSendToken() public {
        vm.startPrank(holder);
        token.approve(address(route), 250 ether);
        vm.expectEmit(true, true, false, true);
        emit NameSent(holder, bob, "bob", address(token), 250 ether);
        route.sendToken("bob", address(token), 250 ether);
        vm.stopPrank();
        assertEq(token.balanceOf(bob), 250 ether);
        assertEq(token.balanceOf(holder), 750 ether);
        // exact-amount approval is fully consumed, nothing lingers
        assertEq(token.allowance(holder, address(route)), 0);
    }

    function testSendTokenNonHolderReverts() public {
        vm.expectRevert(AgenticRoute.NoAgentID.selector);
        vm.prank(stranger);
        route.sendToken("bob", address(token), 1 ether);
    }

    function testSendTokenZeroAmountReverts() public {
        vm.expectRevert(AgenticRoute.ZeroAmount.selector);
        vm.prank(holder);
        route.sendToken("bob", address(token), 0);
    }

    function testSendTokenZeroAddressReverts() public {
        vm.expectRevert(AgenticRoute.ZeroToken.selector);
        vm.prank(holder);
        route.sendToken("bob", address(0), 1 ether);
    }

    function testSendTokenWithoutApprovalReverts() public {
        vm.expectRevert(AgenticRoute.TransferFailed.selector);
        vm.prank(holder);
        route.sendToken("bob", address(token), 10 ether);
    }
}
