// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {ERC721} from "solady/tokens/ERC721.sol";
import {ERC2981} from "solady/tokens/ERC2981.sol";

contract ParticipationTrophy is ERC721, ERC2981 {
    address public immutable $MINTER;
    uint256 public $CURRENT_SUPPLY;

    error NOT_MINTER();

    constructor(address admin, uint96 royalties) {
        $MINTER = msg.sender;
        super._setDefaultRoyalty(admin, royalties);
    }

    function mint(address to) public {
        if (msg.sender != $MINTER) {
            revert NOT_MINTER();
        }
        super._safeMint(to, $CURRENT_SUPPLY++);
    }

    /// ERC721 stuffs

    /// @dev Returns the token collection name.
    function name() public pure override returns (string memory) {
        return "THE LAST DEGEN STANDING PARTICIPATION THROPHY #1";
    }

    /// @dev Returns the token collection symbol.
    function symbol() public pure override returns (string memory) {
        return "LSTDGNTROPHY1";
    }

    /// @dev Returns the Uniform Resource Identifier (URI) for token `id`.
    /// TODO add onchain component with offchain img url, onchain metadata includes last seen timestamp?
    /// NFT might change as number of players is reduced
    function tokenURI(uint256 id) public view override returns (string memory) {
        return "TODO";
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool result) {
        return super.supportsInterface(interfaceId);
    }
}
