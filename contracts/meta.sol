//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "./base64.sol";
import "./Stems.sol";

interface IMeta {
    function getMeta(uint tokenID_) external view returns(string memory);
}

contract Meta {

    function getMeta(uint tokenID_) public view returns(string memory){
        
        IStems.Stem memory stem_ = IStems(msg.sender).getStem(tokenID_);

        bytes memory json_ = abi.encodePacked(
        '{',
        '"name":"stems",',
        '"description":"CC0 shared sound experience",',
        '"image":"https://tokens.blckv2.xyz/STEMS/stems.png",',
        '"audio":"',stem_.audio,'",',
        '"license": "CC0"',
        '}');

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(json_)));
    }

}