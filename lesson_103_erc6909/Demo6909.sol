// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {ERC6909} from "@openzeppelin/token/ERC6909/ERC6909.sol";
import {ERC6909Metadata} from "@openzeppelin/token/ERC6909/extensions/ERC6909Metadata.sol";
import {ERC6909TokenSupply} from "@openzeppelin/token/ERC6909/extensions/ERC6909TokenSupply.sol";

/// @title Demo6909
/// @notice Lecture demo for ERC-6909: one contract, many token ids.
/// @dev Uses OpenZeppelin ERC6909Metadata + ERC6909TokenSupply extensions.
contract Demo6909 is ERC6909Metadata, ERC6909TokenSupply, Ownable {
    // Same contract, different asset ids.
    uint256 public constant TLTK = 1;
    uint256 public constant SILVER = 2;
    uint256 public constant TICKET = 3;
    uint256 public constant LP_CLAIM = 100;

    mapping(address account => bool claimed) public claimedDemoPack;

    error AlreadyClaimed();
    error UnknownTokenId(uint256 id);

    constructor(address initialOwner) Ownable(initialOwner) {
        // Metadata is per token id, not per contract.
        _setName(TLTK, "Tolkien Token");
        _setSymbol(TLTK, "TLTK");
        _setDecimals(TLTK, 18);

        _setName(SILVER, "Lecture Silver");
        _setSymbol(SILVER, "LSILV");
        _setDecimals(SILVER, 6);

        _setName(TICKET, "Lecture Ticket");
        _setSymbol(TICKET, "LTIX");
        _setDecimals(TICKET, 0);

        _setName(LP_CLAIM, "ETH/USDC LP Claim");
        _setSymbol(LP_CLAIM, "ETHUSDC-LP");
        _setDecimals(LP_CLAIM, 18);

        // Initial supply goes to the owner.
        _mint(initialOwner, TLTK, 1_000_000e18);
        _mint(initialOwner, SILVER, 1_000_000_000 * 10 ** 6);
        _mint(initialOwner, TICKET, 1_000);
        _mint(initialOwner, LP_CLAIM, 10_000e18);
    }

    /// @notice Mint demo tokens once per address.
    /// @dev For lecture/demo only. In production, minting policy must be stricter.
    function claimDemoPack() external {
        if (claimedDemoPack[msg.sender]) revert AlreadyClaimed();

        claimedDemoPack[msg.sender] = true;

        _mint(msg.sender, TLTK, 100e18);
        _mint(msg.sender, SILVER, 500 * 10 ** 6);
        _mint(msg.sender, TICKET, 1);
    }

    /// @notice Owner-controlled minting for known token ids.
    function ownerMint(address to, uint256 id, uint256 amount) external onlyOwner {
        _requireKnownId(id);
        _mint(to, id, amount);
    }

    /// @notice Burn your own tokens.
    function burn(uint256 id, uint256 amount) external {
        _burn(msg.sender, id, amount);
    }

    /// @notice Burn someone else's tokens if approved for this id or set as global operator.
    function burnFrom(address from, uint256 id, uint256 amount) external {
        address caller = msg.sender;

        if (from != caller && !isOperator(from, caller)) {
            _spendAllowance(from, caller, id, amount);
        }

        _burn(from, id, amount);
    }

    function _requireKnownId(uint256 id) internal pure {
        if (id != TLTK && id != SILVER && id != TICKET && id != LP_CLAIM) {
            revert UnknownTokenId(id);
        }
    }

    // Required because both ERC6909Metadata and ERC6909TokenSupply implement ERC165 support.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC6909Metadata, ERC6909TokenSupply)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Required because ERC6909TokenSupply overrides _update to track totalSupply(id).
    function _update(address from, address to, uint256 id, uint256 amount)
        internal
        override(ERC6909, ERC6909TokenSupply)
    {
        super._update(from, to, id, amount);
    }
}
