//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "./base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./AudioTokens.sol";

interface IMeta {
    function getMeta(uint token_id_) external view returns(string memory);
}

contract Meta {

    function getMeta(uint token_id_) public view returns(string memory){
        
        IAudioTokens garden_ = IAudioTokens(msg.sender);
        IAudioTokens.Token memory token_ = garden_.getToken(token_id_);

        bytes memory json_ = abi.encodePacked(
        '{',
        '"name":"stems",',
        '"description":"A collaboratove CC0 sound experience",',
        '"image":"',getArtwork(token_id_),'",',
        '"audio":"',token_.audio,'",',
        '"license": "CC0"',
        '}');

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(json_)));
        
    }


    function getArtwork(uint token_id_) public view returns(string memory){

        IAudioTokens garden_ = IAudioTokens(msg.sender);
        // IAudioTokens.Token memory token_ = garden_.getToken(token_id_);
        
        bytes memory svg_ = abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" preserveAspectRatio="xMinYMin meet"> <style> .txt { font-family: Arial, sans-serif; font-size: 100px; letter-spacing: 0.5em; } .green { fill: #00ff00; } .italic { font-style: italic; } .sm { font-size: 12px; } .uc { text-transform: uppercase; } .white { fill: white; } .bold { font-weight: bold; } </style> <defs> <filter xmlns="http://www.w3.org/2000/svg" id="blur" x="-0.1" y="0"><feGaussianBlur in="SourceGraphic" stdDeviation="10"/></filter> <rect id="bg" width="1000" height="1000" x="0" y="0"/> <linearGradient id="g1"> <stop offset="0" stop-color="#000000"> <animate attributeName="offset" begin="0s" dur="10s" values="0;0.1;0" repeatCount="indefinite" /> </stop> <stop offset="0" stop-color="#5f665f"> <animate attributeName="offset" begin="0s" dur="10s" values="0.9;1;0.9" repeatCount="indefinite" /> </stop> </linearGradient> <linearGradient id="g2"> <stop offset="10%" stop-color="#000000" /> <stop offset="80%" stop-color="#a8009a" /> </linearGradient> </defs> <g clip-path="#bg"> <use href="#bg" fill="white"/> <!-- <use href="#bg" fill="url(#g1)" opacity="0.3"/> --> <use href="#bg" fill="url(#g2)" opacity="0.15"/> <text filter="url(#blur)" class="txt italic green" width="900" transform="translate(50, 400)"> <tspan x="0" y="1em">Dirt</tspan> <tspan x="320" y="2.5em">speaks</tspan> <tspan x="0" y="3.7em">truth</tspan> </text> <text class="txt italic sm white uc" transform="translate(30, 35)" opacity="1"> <tspan x="900" y="0">',garden_.getString('name'),'</tspan> <tspan x="0" y="0">#',token_id_ < 10 ? string(abi.encodePacked('0', Strings.toString(token_id_))) : Strings.toString(token_id_),'</tspan> </text> </g> </svg>');

        return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(svg_)));

    }

}