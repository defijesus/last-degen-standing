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
          
       presents

  The Last Degen Standing

Rules are simple. 1 Player = 1 Address = 1 transferable Playing NFT
Each player pays for the ticket to join the game. The ticket funds the prize pool.
When game starts, each player has to say gm EVERY 24h. Else they can, and WILL be deleted.
You can say gm for your frens, if they are afk or something.
Deleting a player pays the hunter a bounty.
If a player wants to give up he can (1) sell his NFT or (2) commit Seppuku and get a partial refund.
Last player alive takes all the pooled eth.

good luck & have fun
*/

pragma solidity ^0.8.19;

import { ERC721 } from "solady/tokens/ERC721.sol";
import { ParticipationTrophy } from "./ParticipationTrophy.sol";

/// fees are expressed in bps 1%=100 3%=300 10%=1000 33%=3300
contract LastDegenStanding is ERC721 {
    uint256 public immutable $TICKET_PRICE;
    uint256 public immutable $ADMIN_FEE;
    uint256 public immutable $SEPPUKU_FEE;
    uint256 public immutable $INVITER_FEE;

    address public immutable $ADMIN;
    ParticipationTrophy public immutable $PARTICIPATION_TROPHY;

    uint256 public $DELETE_FEE;
    uint256 public $PLAYERS_ALIVE;
    uint256 public $GAME_STARTED;

    mapping(uint256 tokenId => uint256 timestamp) public $LAST_SEEN;

    error INCORRECT_PAYMENT();
    error TOO_MANY();
    error CANT_BE_DELETED();
    error ALREADY_PLAYING();
    error IS_NOT_OVER();
    error GAME_NOT_STARTED();
    error ONLY_OWNER();

    event NewPlayer(address indexed player, address invitedBy);
    event GameStarted(uint256 timestamp);
    event GoodMorning(address indexed player, uint256 timestamp);
    event PlayersDeleted(address indexed hunter, uint256[] players);
    event Seppuku(address indexed player);
    event Winner(address indexed player);

    modifier gameHasStarted() {
        if ($GAME_STARTED == 0) {
            revert GAME_NOT_STARTED();
        }
        _;
    }

    constructor(
        uint256 buyInFee,
        uint256 adminFee,
        uint256 deleteFee,
        uint256 seppukuFee,
        uint256 inviterFee,
        address trophyRoyaltiesReceiver,
        uint96 trophyRoyalties
    ) {
        $TICKET_PRICE = buyInFee;
        $ADMIN_FEE = adminFee;
        $DELETE_FEE = deleteFee;
        $SEPPUKU_FEE = seppukuFee;
        $INVITER_FEE = inviterFee;
        $ADMIN = msg.sender;
        $PARTICIPATION_TROPHY = new ParticipationTrophy(trophyRoyaltiesReceiver, trophyRoyalties);
    }

    function join() public payable {
        require($GAME_STARTED == 0);
        if (super.balanceOf(msg.sender) > 0) {
            revert ALREADY_PLAYING();
        }
        if (msg.value != $TICKET_PRICE) {
            revert INCORRECT_PAYMENT();
        }

        super._safeMint(msg.sender, $PLAYERS_ALIVE++);

        unchecked {
            (bool s,) = $ADMIN.call{ value: (msg.value * $ADMIN_FEE) / 10_000 }("");
            require(s);
        }
        emit NewPlayer(msg.sender, address(0));
    }

    function joinWithInvite(address invitedBy) public payable {
        require($GAME_STARTED == 0);
        require(invitedBy != msg.sender && super.balanceOf(invitedBy) > 0);
        if (super.balanceOf(msg.sender) > 0) {
            revert ALREADY_PLAYING();
        }
        if (msg.value != $TICKET_PRICE) {
            revert INCORRECT_PAYMENT();
        }

        super._safeMint(msg.sender, $PLAYERS_ALIVE++);

        unchecked {
            (bool s,) = $ADMIN.call{ value: (msg.value * $ADMIN_FEE) / 10_000 }("");
            require(s);
            (s,) = invitedBy.call{ value: (msg.value * $INVITER_FEE) / 10_000 }("");
            require(s);
        }

        emit NewPlayer(msg.sender, invitedBy);
    }

    function gm(uint256 tokenId) public gameHasStarted {
        $LAST_SEEN[tokenId] = block.timestamp;
        emit GoodMorning(super.ownerOf(tokenId), block.timestamp);
    }

    /// to all searchooooors, pls delete all the players
    /// yes, there might be a chance where all players get deleted and no one gets the prize
    /// it do be designed as intended
    function deletePlayers(uint256[] calldata tokenIds) public gameHasStarted {
        if (tokenIds.length > 20) {
            revert TOO_MANY();
        }
        uint256 i = 0;
        for (; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];
            address owner = super.ownerOf(tokenId);
            if (getLastSeen(tokenId) + 24 hours > block.timestamp) {
                revert CANT_BE_DELETED();
            }

            deletePlayer(owner, tokenId);

            unchecked {
                i++;
            }
        }
        unchecked {
            (bool a,) = msg.sender.call{ value: (($TICKET_PRICE * tokenIds.length) * $DELETE_FEE) / 10_000 }("");
            require(a);
        }

        emit PlayersDeleted(msg.sender, tokenIds);
    }

    function seppuku(uint256 tokenId) public gameHasStarted {
        address owner = super.ownerOf(tokenId);
        if (owner != msg.sender) {
            revert ONLY_OWNER();
        }
        deletePlayer(owner, tokenId);

        unchecked {
            (bool a,) = msg.sender.call{ value: ($TICKET_PRICE * $SEPPUKU_FEE) / 10_000 }("");
            require(a);
        }

        emit Seppuku(msg.sender);
    }

    function win(uint256 tokenId) public gameHasStarted {
        if ($PLAYERS_ALIVE > 1) {
            revert IS_NOT_OVER();
        }

        address winner = super.ownerOf(tokenId);

        (bool a,) = winner.call{ value: address(this).balance }("");
        require(a);

        emit Winner(winner);
    }

    /// ONLY ADMIN ///

    function startGame() public {
        require($GAME_STARTED == 0 && msg.sender == $ADMIN);
        $GAME_STARTED = block.timestamp;
        emit GameStarted(block.timestamp);
    }

    /// depending on gas costs, the hunter might not be economically incentivised to delete players
    ///     so I might have to adjust hunter fee per deletion to keep the game going
    function setFees(uint256 deleteFee) public {
        require(msg.sender == $ADMIN);
        $DELETE_FEE = deleteFee;
    }

    /// INTERNAL ///
    function deletePlayer(address owner, uint256 tokenId) internal {
        super._burn(tokenId);
        $PARTICIPATION_TROPHY.mint(owner);
        $PLAYERS_ALIVE--;
    }

    /// ERC721 & VIEW ///

    function getLastSeen(uint256 tokenId) public view returns (uint256) {
        uint256 lastSeen = $LAST_SEEN[tokenId];
        if (lastSeen == 0) {
            return $GAME_STARTED;
        }
        return lastSeen;
    }

    /// @dev Returns the token collection name.
    function name() public pure override returns (string memory) {
        return "THE LAST DEGEN STANDING";
    }

    /// @dev Returns the token collection symbol.
    function symbol() public pure override returns (string memory) {
        return "LSTDGN";
    }

    /// @dev Returns the Uniform Resource Identifier (URI) for token `id`.
    /// TODO add onchain component with offchain img url, onchain metadata includes last seen timestamp?
    /// NFT might change as number of players is reduced
    function tokenURI(uint256 id) public view override returns (string memory) {
        return "TODO";
    }

    function _beforeTokenTransfer(address from, address to, uint256 id) internal override {
        if (to != address(0) && super.balanceOf(to) > 0) {
            revert ALREADY_PLAYING();
        }
    }
}
