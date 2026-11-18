// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice Testnet-only stand-in for the Agent ID registry, mirroring the
///         real registry's read API (balanceOf / ownerOfHandle / handleOf)
///         so AgenticRoute can be rehearsed end-to-end on BSC testnet.
///         NOT part of the production deployment.
contract TestRegistry {
    mapping(address => uint256) public balanceOf;
    mapping(bytes32 => address) private _owners;
    mapping(address => string) private _handles;

    function setHolder(address who, uint256 n) external {
        balanceOf[who] = n;
    }

    function setHandle(string calldata handle, address owner) external {
        _owners[keccak256(bytes(handle))] = owner;
        _handles[owner] = handle;
    }

    function ownerOfHandle(string calldata handle) external view returns (address) {
        return _owners[keccak256(bytes(handle))];
    }

    function handleOf(address owner) external view returns (string memory) {
        return _handles[owner];
    }
}
