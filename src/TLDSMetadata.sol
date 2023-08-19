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

import { ITLDS_Metadata } from "./ITLDSMetadata.sol";

contract TLDSMetadata is ITLDS_Metadata {
    string public $IMAGE_URI;

    function setImageURI(string calldata imageURI) public {
        require(msg.sender == 0xDe30040413b26d7Aa2B6Fc4761D80eb35Dcf97aD);
        $IMAGE_URI = imageURI;
    }
    function getImageURI(uint256) public view returns (string memory) {
        return $IMAGE_URI;
    }
}