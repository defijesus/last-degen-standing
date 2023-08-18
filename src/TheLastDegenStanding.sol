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

Rules are simple. 1 Degen = 1 Address = 1 transferable Playing NFT

Each Degen pays for the ticket to join the game. The ticket funds the prize pool.

When game starts, each degen has to say gm EVERY 24h. Else they can, and WILL be deleted.

You can say gm for your frens, if they are afk or something.

Deleting a degen pays the hunter a bounty.

If a degen wants to give up he can (1) sell his NFT or (2) commit Seppuku and get a partial refund. Last degen alive
takes all the pooled eth.

good luck & have fun
*/

pragma solidity ^0.8.19;

import { ERC721 } from "solady/tokens/ERC721.sol";
import { TheParticipationTrophy } from "./TheParticipationTrophy.sol";

/// fees are expressed in bps 1%=100 3%=300 10%=1000 33%=3300
contract TheLastDegenStanding is ERC721 {
    uint256 public constant $TICKET_PRICE = 0.03 ether;
    uint256 public constant $ADMIN_FEE = 500;
    uint256 public constant $SEPPUKU_FEE = 1000;
    uint256 public constant $INVITER_FEE = 500;
    uint256 public constant $DEGEN_COOLDOWN = 24 hours;
    uint96 public constant $TROPHY_ROYALTIES_FEE = 1000;
    address public constant $TROPHY_ROYALTIES_RECEIVER = address(123); // TODO
    
    TheParticipationTrophy public immutable $THE_PARTICIPATION_TROPHY;

    /// not constant due to possible changing economic incentives
    uint256 public $DELETE_FEE;
    uint256 public $DEGENS_ALIVE;
    /// timestamp of the last degen that joined the game
    uint256 public $LAST_DEGEN_IN;
    /// timestamp of when the game started
    uint256 public $GAME_STARTED;
    address public $ADMIN = 0xDe30040413b26d7Aa2B6Fc4761D80eb35Dcf97aD;

    mapping(uint256 tokenId => uint256 timestamp) public $LAST_SEEN;

    error INCORRECT_PAYMENT();
    error TOO_MANY();
    error CANT_BE_DELETED();
    error ALREADY_PLAYING();
    error IS_NOT_OVER();
    error GAME_NOT_STARTED();
    error ONLY_OWNER();
    error CANT_START_GAME();

    event NewDegen(address indexed degen);
    event NewFriendlyDegen(address indexed degen, address invitedBy);
    event GameStarted(uint256 timestamp);
    event GM(address indexed degen, uint256 timestamp);
    event DegensDeleted(address indexed hunter, uint256[] degens);
    event Seppuku(address indexed degen);
    event Winner(address indexed degen);

    modifier gameHasStarted() {
        if ($GAME_STARTED == 0) {
            revert GAME_NOT_STARTED();
        }
        _;
    }

    constructor() {
        $THE_PARTICIPATION_TROPHY = new TheParticipationTrophy($TROPHY_ROYALTIES_RECEIVER, $TROPHY_ROYALTIES_FEE);
        $LAST_DEGEN_IN = block.timestamp;
    }

    function join() public payable {
        require($GAME_STARTED == 0);
        if (super.balanceOf(msg.sender) != 0) {
            revert ALREADY_PLAYING();
        }
        if (msg.value != $TICKET_PRICE) {
            revert INCORRECT_PAYMENT();
        }

        $LAST_DEGEN_IN = block.timestamp;

        super._safeMint(msg.sender, $DEGENS_ALIVE++);

        unchecked {
            (bool s,) = $ADMIN.call{ value: (msg.value * $ADMIN_FEE) / 10_000 }("");
            require(s);
        }
        emit NewDegen(msg.sender);
    }

    function joinWithInvite(address invitedBy) public payable {
        require($GAME_STARTED == 0);
        require(invitedBy != msg.sender && super.balanceOf(invitedBy) != 0);
        if (super.balanceOf(msg.sender) != 0) {
            revert ALREADY_PLAYING();
        }
        if (msg.value != $TICKET_PRICE) {
            revert INCORRECT_PAYMENT();
        }

        $LAST_DEGEN_IN = block.timestamp;

        super._safeMint(msg.sender, $DEGENS_ALIVE++);

        unchecked {
            (bool s,) = $ADMIN.call{ value: (msg.value * $ADMIN_FEE) / 10_000 }("");
            require(s);
            (s,) = invitedBy.call{ value: (msg.value * $INVITER_FEE) / 10_000 }("");
            require(s);
        }

        emit NewFriendlyDegen(msg.sender, invitedBy);
    }

    function startGame() public {
        if (
            $GAME_STARTED != 0 ||
            ($LAST_DEGEN_IN + $DEGEN_COOLDOWN) > block.timestamp
        ) {
            revert CANT_START_GAME();
        }
        $GAME_STARTED = block.timestamp;
        emit GameStarted(block.timestamp);
    }

    function gm(uint256 tokenId) public gameHasStarted {
        $LAST_SEEN[tokenId] = block.timestamp;
        emit GM(super.ownerOf(tokenId), block.timestamp);
    }

    /// to all searchooooors, pls delete all the degens
    /// yes, there might be a chance where all degens get deleted and no one gets the prize
    /// it do be designed as intended
    function deleteDegens(uint256[] calldata tokenIds) public gameHasStarted {
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

            deleteDegen(owner, tokenId);

            unchecked {
                i++;
            }
        }
        unchecked {
            (bool a,) = msg.sender.call{ value: (($TICKET_PRICE * tokenIds.length) * $DELETE_FEE) / 10_000 }("");
            require(a);
        }

        emit DegensDeleted(msg.sender, tokenIds);
    }

    function seppuku(uint256 tokenId) public gameHasStarted {
        address owner = super.ownerOf(tokenId);
        if (owner != msg.sender) {
            revert ONLY_OWNER();
        }
        deleteDegen(owner, tokenId);

        unchecked {
            (bool a,) = msg.sender.call{ value: ($TICKET_PRICE * $SEPPUKU_FEE) / 10_000 }("");
            require(a);
        }

        emit Seppuku(msg.sender);
    }

    function win(uint256 tokenId) public gameHasStarted {
        if ($DEGENS_ALIVE != 1) {
            revert IS_NOT_OVER();
        }

        address winner = super.ownerOf(tokenId);

        (bool a,) = winner.call{ value: address(this).balance }("");
        require(a);

        emit Winner(winner);
    }

    /// if u (as a searcher) manage to delete all the players, feel free to take the pot :)
    /// I'll double dip on the fee tho, hope u don't mind
    function everyoneLost() public gameHasStarted {
        if ($DEGENS_ALIVE != 0) {
            revert IS_NOT_OVER();
        }
        address winner = msg.sender;

        unchecked {
            (bool s,) = $ADMIN.call{ value: (address(this).balance * $ADMIN_FEE) / 10_000 }("");
            require(s);
        }

        (bool a,) = winner.call{ value: address(this).balance }("");
        require(a);

        emit Winner(winner);
    }

    /// ONLY ADMIN ///

    /// depending on gas costs, the hunter might not be economically incentivised to delete degens
    ///     so the admin might have to adjust hunter fee per deletion to keep the game going
    /// considering turning this admin into a partydao controlled by nft holders
    function setFees(uint256 deleteFee) public {
        require(msg.sender == $ADMIN);
        $DELETE_FEE = deleteFee;
    }

    /// Justin Case
    function gibAdmin(address newAdmin) public {
        require(msg.sender == $ADMIN);
        $ADMIN = newAdmin;
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
        return "TLDS";
    }

    /// @dev Returns the Uniform Resource Identifier (URI) for token `id`.
    /// TODO add onchain component with offchain img url, onchain metadata includes last seen timestamp?
    /// NFT might change as number of degens is reduced
    function tokenURI(uint256 id) public view override returns (string memory) {
        return "TODO";
    }

    /// INTERNAL ///
    function deleteDegen(address owner, uint256 tokenId) internal {
        super._burn(tokenId);
        $THE_PARTICIPATION_TROPHY.mint(owner);
        $DEGENS_ALIVE--;
    }

    function _beforeTokenTransfer(address, address to, uint256) internal view override {
        if (to != address(0) && super.balanceOf(to) > 0) {
            revert ALREADY_PLAYING();
        }
    }
}
