//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "./base64.sol";
import "./stems.sol";

interface Imeta {
    function getMeta(uint tokenID_) external view returns(string memory);
}

contract meta {

    function getMeta(uint tokenID_) public view returns(string memory){
        
        Istems.Stem memory stem_ = Istems(msg.sender).getStem(tokenID_);

        bytes memory json_ = abi.encodePacked(
        '{',
        '"name":"stems",',
        '"description":"CC0 shared sound experience",',
        '"image":"https://tokens.blckv2.xyz/STEMS/stems.png",',
        '"audio":"',stem_.audio,'",',
        '"license": "CC0"',
        '}');

        return Base64.encode(json_);
    }

}