//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Meta.sol";

/**

____    ___    ____    _  _    ____ 
[__      |     |___    |\/|    [__  
___]     |     |___    |  |    ___] 
          
           g a r d e n

*/


interface IStemsGarden is IERC721 {

    struct Stem {
        string audio;
        uint season;
    }

    struct Season {
        string audio;
        uint begin;
        uint supply;
    }

    function createSeason(string memory audio_, uint amount_, uint begin_) external;
    function currentSeasonIndex() external view returns(uint);
    function getSeason(uint season_) external view returns(IStemsGarden.Season memory);
    function seasonOpen() external view returns(bool);
    function hasMintedSeason(uint season_, address check_) external view returns(bool);
    function mint(string memory audio_) external ;
    function updateStemAudio(uint stemID_, string memory audio_) external;
    function setMetaAddress(address meta_) external;
    function getStem(uint stemID_) external view returns(IStemsGarden.Stem memory);


}

contract StemsGarden is ERC721, Ownable, ReentrancyGuard {
    
    uint public constant TIMEOUT = 7 days;

    uint private _stem_ids;
    mapping(uint => IStemsGarden.Stem) private _stems;
    mapping(uint => mapping(address => bool)) private _minters;

    uint private _season;
    mapping(uint => IStemsGarden.Season) private _seasons;

    address private _meta;

    modifier onlyHolder(uint stemID){
        require(ownerOf(stemID) == msg.sender, 'NOT_TOKEN_HOLDER');
        _;
    }


    //// EVENTS

    event AudioUpdated(uint indexed stemID, string oldUri, string newUri);

    constructor() ERC721("StemsGarden", "STEM"){
        Meta meta_ = new Meta();
        _meta = address(meta_);
    }


    function createSeason(string memory audio_, uint amount_, uint begin_) public onlyOwner {

        _season++;

        _seasons[_season] = IStemsGarden.Season(
            audio_,
            block.timestamp+begin_,
            amount_
        );

    }

    function currentSeasonIndex() public view returns(uint){
        return _season;
    }

    function getSeason(uint season_) public view returns(IStemsGarden.Season memory){
        return season_ == 0 ? _seasons[_season] : _seasons[season_];
    }


    function seasonOpen() public view returns(bool){
        return (block.timestamp > _seasons[_season].begin);
    }


    function hasMintedSeason(uint season_, address check_) public view returns(bool){
        return _minters[season_][check_];
    }


    function mint(string memory audio_) public nonReentrant {
        
        require(seasonOpen(), 'SEASON_CLOSED');
        require(_stem_ids <= _seasons[_season].supply, 'OUT_OF_SEASON');
        require(!hasMintedSeason(_season, msg.sender), 'ALREADY_MINTED_SEASON');

        _minters[_season][msg.sender] = true;

        _stem_ids++;
        _stems[_stem_ids] = IStemsGarden.Stem(
            audio_,
            _season
        );
        
        _mint(msg.sender, _stem_ids);
        
    }

    function updateStemAudio(uint stemID_, string memory audio_) public onlyHolder(stemID_) {
        string memory oldUri = _stems[stemID_].audio;
        _stems[stemID_].audio = audio_;
        emit AudioUpdated(stemID_, oldUri, audio_);
    }


    function setMetaAddress(address meta_) public onlyOwner(){
        _meta = meta_;
    }

    function getStem(uint stemID_) public view returns(IStemsGarden.Stem memory){
        return _stems[stemID_];
    }

    function tokenURI(uint stemID_) public view override returns(string memory) {
        return IMeta(_meta).getMeta(stemID_);
    }


}
