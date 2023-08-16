// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract LastDegenStanding {
    uint256 immutable $BUY_IN;
    uint256 immutable $FEE;

    uint256 $PLAYERS_ALIVE;

    mapping(address => uint256) $LAST_SEEN;
    mapping(address => bool) $IS_PLAYER;
    mapping(address => bool) $IS_DELETED;

    error BUY_IN_AMOUNT_INCORRECT();
    error TOO_MANY();
    error NOT_PLAYER();
    error CANT_BE_DELETED();
    error ALREADY_PLAYING();
    error IS_NOT_OVER();

    constructor(uint256 buyin, uint256 fee) {
        $BUY_IN = buyin;
        $FEE = fee;
    }

    function join() public payable {
        if ($IS_PLAYER[msg.sender]) {
            revert ALREADY_PLAYING();
        }
        if (msg.value != $BUY_IN) {
            revert BUY_IN_AMOUNT_INCORRECT();
        }
        $IS_PLAYER[msg.sender] = true;
        $PLAYERS_ALIVE++;
    }

    function gm() public {
        $LAST_SEEN[msg.sender] = block.timestamp;
    }

    function win() public {
        if ($PLAYERS_ALIVE > 1) {
            revert IS_NOT_OVER();
        }
        if (!$IS_PLAYER[msg.sender]) {
            revert IS_NOT_OVER();
        }
        if ($IS_DELETED[msg.sender]) {
            revert IS_NOT_OVER();
        }
        (bool a,) = msg.sender.call{value: address(this).balance}("");
        require(a);
    }

    function deletePlayers(address[] memory players) public {
        if (players.length > 20) {
            revert TOO_MANY();
        }
        uint256 i = 0;
        uint256 reward = 0;
        for(; i<players.length;) {
            address player = players[i];

            if (!$IS_PLAYER[player]) {
                revert NOT_PLAYER();
            }

            if (
                !$IS_DELETED[player] &&
                $LAST_SEEN[player] + 24 hours < block.timestamp
            ) {
                $IS_DELETED[player] = true;
                $PLAYERS_ALIVE--;
            } else {
                revert CANT_BE_DELETED();
            }

            unchecked {
                i++;
            }
        }

        (bool a,) = msg.sender.call{value: reward}("");
        require(a);
    }

    function deleteme() public {
        if ($IS_DELETED[msg.sender]) {
            revert CANT_BE_DELETED();
        }
        $IS_DELETED[msg.sender] = true;
        $PLAYERS_ALIVE--;
        (bool a,) = msg.sender.call{value: $BUY_IN/10}("");
        require(a);
    }
}
