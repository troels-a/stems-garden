//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Meta.sol";

/**

____   ___   ____   _  _   ____ 
[__     |    |___   |\/|   [__  
___]    |    |___   |  |   ___] 
                         
collaborative CC0 audio project

*/


interface IStems is IERC721 {

    struct Stem {
        string audio;
        uint season;
    }

    struct Season {
        string audio;
        uint begin;
        uint supply;
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

contract Stems is ERC721, Ownable, ReentrancyGuard {
    
    uint public constant TIMEOUT = 7 days;

    uint private _stem_ids;
    mapping(uint => IStems.Stem) private _stems;
    mapping(uint => mapping(address => bool)) private _minters;

    uint private _season;
    mapping(uint => IStem.Season) private _seasons;

    address private _meta;

    modifier onlyHolder(uint stemID){
        require(ownerOf(stemID) == msg.sender, 'NOT_TOKEN_HOLDER');
        _;
    }


    //// EVENTS

    event AudioUpdated(uint indexed stemID, string oldUri, string newUri);

    constructor() ERC721("Stems", "STEM"){
        Meta meta_ = new Meta();
        _meta = address(meta_);
    }


    function createSeason(string audio_, uint amount_, uint begin_) public onlyOwner {

        _season++;

        _seasons[_seasons] = IStems.Season(
            audio_,
            block.timestamp+begin_,
            amount_
        );

    }

    function getSeason(uint season_) public returns(IStems.Season){
        return season_ == 0 ? _seasons[_season] : _seasons[season_];
    }


    function seasonOpen() public returns(bool){
        return (_seasons[_season].begin > block.timestamp);
    }


    function hasMintedSeason(uint season_, address check_) public view returns(bool){
        return _minters[season_][check_];
    }


    function mint(string memory audio_) public nonReentrant {
        
        require(seasonOpen(), 'SEASON_CLOSED');
        require(_stem_ids <= _amounts[_season], 'OUT_OF_SEASON');
        require(!hasMintedSeason(_season, msg.sender), 'ALREADY_MINTED_SEASON');

        _minters[_season][msg.sender] = true;

        _stem_ids++;
        _stems[_stem_ids] = IStems.Stem(
            audio_,
            _season
        );
        
        _mint(msg.sender, _stem_ids);
        IMeta(_meta).afterMint(_stem_ids);

    }

    function updateStemAudio(uint stemID_, string memory audio_) public onlyHolder(stemID_) {
        require(!_stems[stemID_].locked, 'STEM_LOCKED');
        string memory oldUri = _audio[stemID_];
        _stems[stemID_].audio = audio_;
        emit StemAudioUpdated(stemID_, oldUri, audio_);
    }


    function setMetaAddress(address meta_) public onlyOwner(){
        _meta = meta_;
    }

    function getStem(uint stemID_) public view returns(IStems.Stem memory){
        return _stems[stemID_];
    }

    function tokenURI(uint stemID_) public view override returns(string memory) {
        return IMeta(_meta).getMeta(stemID_);
    }


}
