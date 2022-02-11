//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./meta.sol";

interface Istems is IERC721 {

    struct Stem {
        address owner;
        string audio;
    }

    function getStem(uint stemID_) external view returns(Stem memory);
    function updateAudio(uint stemID_, string memory audio_) external;
    function setMetaAddress(address meta_) external;

}

contract stems is ERC721, Ownable {
    
    uint public constant TIMEOUT = 7 days;

    uint private _stem_ids;
    uint private _expiration;
    address private _next;
    mapping(uint => string) private _audio;
    mapping(address => bool) private _contributors;

    address private _meta;

    modifier onlyHolder(uint stemID){
        require(ownerOf(stemID) == msg.sender, 'NOT_TOKEN_HOLDER');
        _;
    }

    constructor() ERC721("Stems", "STEM"){
        meta meta_ = new meta();
        _meta = address(meta_);
        _next = msg.sender;
        _expiration = block.timestamp+TIMEOUT;
    }

    function pass(string memory audio_, address next_) public {
        
        require((msg.sender == _next || msg.sender == ownerOf(_stem_ids)), 'INVALID_CALLER');
        require(_contributors[next_], 'NEXT_ALREADY_CONTRIBUTED');

        if((msg.sender == _next && block.timestamp <= _expiration)){
            _mintFor(msg.sender, audio_);
            _next = next_;
        }
        else if(
            block.timestamp > _expiration && // Deadline expired
            msg.sender == ownerOf(_stem_ids) && // Owns previous
            msg.sender != next_ // Next is not caller
        ){
            _next = next_;
        }
        else {
            revert("COULD_NOT_PASS");
        }
        
    }


    function _mintFor(address for_, string memory audio_) private {
        
        _stem_ids++;
        _expiration = block.timestamp+TIMEOUT;
        _audio[_stem_ids] = audio_;
        
        _mint(for_, _stem_ids);

    }

    function updateAudio(uint stemID_, string memory audio_) public onlyHolder(stemID_) {
        _audio[stemID_] = audio_;
    }

    function setMetaAddress(address meta_) public onlyOwner(){
        _meta = meta_;
    }

    function getStem(uint stemID_) public view returns(Istems.Stem memory){
        return Istems.Stem(
            ownerOf(stemID_),
            _audio[stemID_]
            );
    }

    function tokenURI(uint stemID_) public view override returns(string memory) {
        return Imeta(_meta).getMeta(stemID_);
    }


}
