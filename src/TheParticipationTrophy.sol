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
import { ITLDS_Metadata } from "./ITLDSMetadata.sol";

interface ITLDS {
    function $GAME_STARTED() external view returns (uint256);
    function $DEGENS_ALIVE() external view returns (uint256);
    function $TLDS_METADATA() external view returns (ITLDS_Metadata);
}

contract TheParticipationTrophy is ERC721, ERC2981 {
    address public immutable $MINTER;
    uint256 public $DEGEN_COUNT;

    bool internal $FIRST_MINT = true;
    uint256 internal $DEGENS_SEEN;

    mapping(uint256 tokenId => uint256 deletedTimestamp) public $WEN_PLAYER_DELETED;
    mapping(uint256 tokenId => uint256 standing) public $DEGEN_STANDINGS;

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
        if ($FIRST_MINT) {
            $DEGEN_COUNT = ITLDS($MINTER).$DEGENS_ALIVE();
            $FIRST_MINT = false;
        }
        $DEGEN_STANDINGS[tokenId] = $DEGEN_COUNT - $DEGENS_SEEN;
        $WEN_PLAYER_DELETED[tokenId] = block.timestamp;
        $DEGENS_SEEN++;
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
        uint256 gameStart = ITLDS($MINTER).$GAME_STARTED();
        uint256 degenDeleted = $WEN_PLAYER_DELETED[tokenId];
        uint256 daysPlayed = (degenDeleted - gameStart) / 86400;
        uint256 place = $DEGEN_STANDINGS[tokenId];
        string memory imageURI = ITLDS_Metadata(ITLDS($MINTER).$TLDS_METADATA()).getTrophyURI(tokenId);
        string memory json = Helpers.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Deleted Degen #',
                        Helpers.toString(tokenId),
                        '", "attributes": [{"display_type": "date", "trait_type": "Joined", "value": ',
                        Helpers.toString(gameStart),
                        '}, {"display_type": "date", "trait_type": "Deleted", "value": ',
                        Helpers.toString(degenDeleted),
                        '}, {"display_type": "number", "trait_type": "Place", "value": ',
                        Helpers.toString(place),
                        '}], "description": "This degen played for ',
                        Helpers.toString(daysPlayed),
                        ' days.", "image": "',
                        imageURI,
                        '"}'    
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
