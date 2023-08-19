// VIRAL PUBLIC LICENSE
// Copyleft (ɔ) All Rights Reversed

// This WORK is hereby relinquished of all associated ownership, attribution and copy
// rights, and redistribution or use of any kind, with or without modification, is
// permitted without restriction subject to the following conditions:

// 1.	Redistributions of this WORK, or ANY work that makes use of ANY of the
// 	contents of this WORK by ANY kind of copying, dependency, linkage, or ANY
// 	other possible form of DERIVATION or COMBINATION, must retain the ENTIRETY
// 	of this license.
// 2.	No further restrictions of ANY kind may be applied.

/*
   _      ΞΞΞΞ      _
  /_;-.__ / _\  _.-;_\
     `-._`'`_/'`.-'
         `\   /`
          |  /
         /-.(
         \_._\
          \ \`;
           > |/
          / //
          |//
          \(\
           ``
     defijesus.eth
*/

pragma solidity ^0.8.19;

import { ERC721 } from "solady/tokens/ERC721.sol";
import { ERC2981 } from "solady/tokens/ERC2981.sol";
import { Helpers } from "./Helpers.sol";

interface ITLDS {
    function $GAME_START() external view returns (uint256);
}

contract TheParticipationTrophy is ERC721, ERC2981 {
    address public immutable $MINTER;

    mapping(uint256 tokenId => uint256 deletedTimestamp) public $WEN_PLAYER_DELETED;

    error NOT_MINTER();

    modifier onlyMinter {
        if (msg.sender != $MINTER) {
            revert NOT_MINTER();
        }
        _;
    }

    constructor(address admin, uint96 royalties) {
        $MINTER = msg.sender;
        super._setDefaultRoyalty(admin, royalties);
    }

    function mint(address to, uint256 tokenId) public onlyMinter {
        $WEN_PLAYER_DELETED[tokenId] = block.timestamp;
        super._safeMint(to, tokenId);
    }

    /// ERC721 stuffs

    /// @dev Returns the token collection name.
    function name() public pure override returns (string memory) {
        return "THE LAST DEGEN STANDING PARTICIPATION THROPHY #1";
    }

    /// @dev Returns the token collection symbol.
    function symbol() public pure override returns (string memory) {
        return "TLDSPT1";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory output) {
        ITLDS tlds = ITLDS($MINTER);
        uint256 gameStart = tlds.$GAME_START();
        uint256 degenDeleted = $WEN_PLAYER_DELETED[tokenId];
        uint256 daysPlayed = (degenDeleted - gameStart) / 86400;
        string memory json = Helpers.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Deleted Degen #',
                        Helpers.toString(tokenId),
                        '","attributes": [{"display_type": "date", "trait_type": "Joined timestamp", "value":',
                        Helpers.toString(gameStart),
                        '},{"display_type": "date", "trait_type": "Deletion timestamp", "value":',
                        Helpers.toString(degenDeleted),
                        '}],"description": "This degen played for ',
                        Helpers.toString(daysPlayed),
                        'days.", "image": "TODO"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool result) {
        return super.supportsInterface(interfaceId);
    }
}
