// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice Minimal view of the official Agent ID registry (HandleRegistry,
///         0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F on BNB Chain).
interface IAgentIDRegistry {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOfHandle(string calldata handle) external view returns (address);
}

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @title AgenticRoute
/// @notice Send BNB or ERC-20 tokens to an Agent ID name (e.g. "0xkylian",
///         displayed as 0xkylian.ai) instead of a raw address.
/// @dev    Design rules, by intent:
///         - Only Agent ID holders can send (registry balanceOf check).
///         - The contract never custodies funds: BNB is forwarded in the same
///           call; tokens move directly sender -> recipient via transferFrom.
///         - No owner, no admin functions, no pause, no upgrade, no fees.
///         - Zero-value sends revert, so usage metrics stay honest.
contract AgenticRoute {
    IAgentIDRegistry public immutable registry;

    /// @notice Emitted on every successful send. token == address(0) = native BNB.
    event NameSent(address indexed from, address indexed to, string handle, address token, uint256 amount);

    error NoAgentID();
    error NameNotFound();
    error ZeroAmount();
    error ZeroToken();
    error TransferFailed();

    constructor(address registry_) {
        registry = IAgentIDRegistry(registry_);
    }

    modifier onlyHolder() {
        if (registry.balanceOf(msg.sender) == 0) revert NoAgentID();
        _;
    }

    /// @notice Resolve an Agent ID handle to its owner's address.
    /// @param handle The handle WITHOUT the ".ai" suffix, e.g. "0xkylian".
    function resolve(string calldata handle) public view returns (address) {
        address to = registry.ownerOfHandle(handle);
        if (to == address(0)) revert NameNotFound();
        return to;
    }

    /// @notice Send native BNB to the owner of `handle`.
    function sendBNB(string calldata handle) external payable onlyHolder {
        if (msg.value == 0) revert ZeroAmount();
        address to = resolve(handle);
        (bool ok,) = to.call{value: msg.value}("");
        if (!ok) revert TransferFailed();
        emit NameSent(msg.sender, to, handle, address(0), msg.value);
    }

    /// @notice Send `amount` of an ERC-20 token to the owner of `handle`.
    /// @dev The sender approves this contract for the exact amount; the tokens
    ///      move directly from sender to recipient. Tokens that return no
    ///      value on transferFrom are accepted (legacy style); a returned
    ///      false or a revert fails the send. Fee-on-transfer tokens deliver
    ///      net of their fee, which the token itself dictates.
    function sendToken(string calldata handle, address token, uint256 amount) external onlyHolder {
        if (amount == 0) revert ZeroAmount();
        if (token == address(0)) revert ZeroToken();
        address to = resolve(handle);
        (bool ok, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, msg.sender, to, amount));
        if (!ok || (data.length > 0 && !abi.decode(data, (bool)))) revert TransferFailed();
        emit NameSent(msg.sender, to, handle, token, amount);
    }
}
