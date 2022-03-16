//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "./base64.sol";
import "./StemsGarden.sol";

interface IMeta {
    function getMeta(uint tokenID_) external view returns(string memory);
}

contract Meta {

    function getMeta(uint tokenID_) public view returns(string memory){
        
        IStemsGarden garden_ = IStemsGarden(msg.sender);
        IStemsGarden.Stem memory stem_ = garden_.getStem(tokenID_);

        bytes memory json_ = abi.encodePacked(
        '{',
        '"name":"stems",',
        '"description":"A collaboratove CC0 sound experience",',
        '"image":"',getArtwork(tokenID_),'",',
        '"audio":"',stem_.audio,'",',
        '"license": "CC0"',
        '}');

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(json_)));
        
    }


    function getArtwork(uint tokenID_) public view returns(string memory){

        bytes memory svg_ = abi.encodePacked('<svg>',
        '<rect>',
        '',
        '</rect>',
        '</svg>');

        return string(abi.encodePacked('data:image/svg-xml;base64,', Base64.encode(svg_)));

    }

}