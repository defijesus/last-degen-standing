// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <=0.9.0;

import { TheLastDegenStanding } from "../src/TheLastDegenStanding.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
/// command: make deploy-ledger contract=script/Deploy.s.sol/:Deploy chain=baldchain
contract Deploy is BaseScript {
    function run() public broadcast {
        TheLastDegenStanding lds = new TheLastDegenStanding();
        lds.join{ value: lds.$TICKET_PRICE() }();
    }
}
