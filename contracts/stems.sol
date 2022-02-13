//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Meta.sol";

/**

____   ___   ____   _  _   ____ 
[__     |    |___   |\/|   [__  
___]    |    |___   |  |   ___] 
                         
collaborative CC0 audio project

*/


interface IStems is IERC721 {

    struct Stem {
        address owner;
        string audio;
    }

    function next() external view returns(address);
    function timeLeft() external view returns(int seconds_);
    function hasContributed(address check_) external view returns(bool);
    function mint(string memory audio_, address next_) external;
    function delegateNext(address next_) external;
    function updateAudio(uint stemID_, string memory audio_) external;
    function setMetaAddress(address meta_) external;
    function getStem(uint stemID_) external view returns(IStems.Stem memory);

}

contract Stems is ERC721, Ownable {
    
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


    //// EVENTS

    event AudioUpdated(uint indexed stemID, string oldUri, string newUri);
    event NextDelegated(address indexed next, address indexed delegator);

    constructor() ERC721("Stems", "STEM"){
        Meta meta_ = new Meta();
        _meta = address(meta_);
        _next = msg.sender;
        _expiration = block.timestamp*365 days;
    }

    function next() public view returns(address){
        return _next;
    }

    function timeLeft() public view returns(int seconds_){
        if(_expiration > block.timestamp)
            return int(_expiration - block.timestamp);
        return 0;
    }


    function hasContributed(address check_) public view returns(bool){
        return _contributors[check_];
    }


    function mint(string memory audio_, address next_) public {
        
        require(next() == msg.sender, 'NOT_NEXT');
        require(timeLeft() > 0, 'EXPIRED');

        _delegateNext(next_, msg.sender);
        _resetExpiration();
        _contributors[msg.sender] = true;

        _mintFor(msg.sender, audio_);
        
    }


    function delegateNext(address next_) public onlyOwner {
        
        require(!_contributors[next_], 'PREVIOUSLY_DELEGATED');
        require(timeLeft() < 1, 'NOT_EXPIRED');

        _delegateNext(next_, msg.sender);
        _resetExpiration();

    }


    function _delegateNext(address next_, address by_) private {
        _next = next_;
        emit NextDelegated(next_, by_);
    }

    
    function _resetExpiration() private {
        _expiration = block.timestamp + TIMEOUT;
    }


    function _mintFor(address for_, string memory audio_) private {
        
        _stem_ids++;
        _audio[_stem_ids] = audio_;
        
        _mint(for_, _stem_ids);

    }

    function updateAudio(uint stemID_, string memory audio_) public onlyHolder(stemID_) {
        string memory oldUri = _audio[stemID_];
        _audio[stemID_] = audio_;
        emit AudioUpdated(stemID_, oldUri, audio_);
    }

    function setMetaAddress(address meta_) public onlyOwner(){
        _meta = meta_;
    }

    function getStem(uint stemID_) public view returns(IStems.Stem memory){
        return IStems.Stem(
            ownerOf(stemID_),
            _audio[stemID_]
            );
    }

    function tokenURI(uint stemID_) public view override returns(string memory) {
        return IMeta(_meta).getMeta(stemID_);
    }


}
