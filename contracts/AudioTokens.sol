//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PollyModule.sol";
import "./Meta.sol";

/**

____    ___    ____    _  _    ____ 
[__      |     |___    |\/|    [__  
___]     |     |___    |  |    ___] 
          
           g a r d e n

*/


interface IAudioTokens is IERC721, IPollyModule {

    struct Token {
        string audio;
        uint batch;
    }

    struct Batch {
        string audio;
        uint begin;
        uint supply;
        uint price;
        address recipient;
    }

    function createBatch(string memory audio_, uint amount_, uint begin_) external;
    function currentBatchIndex() external view returns(uint);
    function getBatch(uint batch_index_) external view returns(IAudioTokens.Batch memory);
    function batchAvailable() external view returns(bool);
    function getAvailable() external view returns(uint);
    function leftForAddressInBatch(uint batch_index_, address check_) external view returns(bool);
    function mint(string memory audio_) external ;
    function updateTokenAudio(uint token_id_, string memory audio_) external;
    function setMetaAddress(address meta_) external;
    function getToken(uint token_id_) external view returns(IAudioTokens.Token memory);


}

contract AudioTokens is ERC721, PollyModule, ReentrancyGuard {

    uint private _token_ids;
    mapping(uint => IAudioTokens.Token) private _tokens;
    mapping(uint => mapping(address => uint)) private _minters;

    uint private _batch;
    mapping(uint => IAudioTokens.Batch) private _batches;

    address private _meta;

    modifier onlyHolder(uint tokenID){
        require(ownerOf(tokenID) == msg.sender, 'NOT_TOKEN_HOLDER');
        _;
    }


    //// EVENTS

    event AudioUpdated(uint indexed tokenID, string oldUri, string newUri);

    constructor() ERC721("", ""){
    }

    function getModuleInfo() public view returns(IPollyModule.ModuleInfo memory){
        return IPollyModule.ModuleInfo('Tokens Garden', address(this), true);
    }

    function init(address for_) public override {
        super.init(for_);
    }

    function createBatch(string memory audio_, uint amount_, uint begin_, uint price_, address recipient_) public onlyRole(DEFAULT_ADMIN_ROLE) {

        _batch++;
        _token_ids = 10000*_batch;
        _batches[_batch] = IAudioTokens.Batch(
            audio_,
            block.timestamp+begin_,
            amount_,
            price_,
            recipient_
        );

    }

    function createBatchPremint(string memory audio_, uint amount_, uint begin_, uint price_, address recipient_, address[] memory premints_) public onlyRole(DEFAULT_ADMIN_ROLE) {

        createBatch(audio_, amount_, begin_, price_, recipient_);

        if(premints_.length < 1)
            return;

        uint i = 0;
        while(i < premints_.length) {
            _mintTo(premints_[i], '');
            unchecked {++i;}
        }

    }

    function currentBatchIndex() public view returns(uint){
        return _batch;
    }

    function getBatch(uint batch_index_) public view returns(IAudioTokens.Batch memory){
        return batch_index_ == 0 ? _batches[_batch] : _batches[batch_index_];
    }


    function batchAvailable() public view returns(bool){
        return (_batch > 0 && block.timestamp > _batches[_batch].begin && getAvailable() > 0);
    }

    function getAvailable() public view returns(uint){
        return _batch > 0 ? _batches[_batch].supply - (_token_ids - (_batch*10000)) : 0;
    }

    function canMintCurrentBatch(uint batch_index_, address check_) public view returns(bool){

        uint max = getUint('max_mints');
        if(max == 0)
            return true;
        return (_minters[batch_index_][check_] < max);

    }

    function mint(string memory audio_) public payable nonReentrant {

        IAudioTokens.Batch memory batch_ = getBatch(_batch);
        require(batch_.price == msg.value, 'INVALID_VALUE');
        require(batchAvailable(), 'BATCH_UNAVAILABLE');
        require(canMintCurrentBatch(_batch, msg.sender), 'MINT_THRESHOLD_EXCEEDED');

        if(batch_.price > 0){
            (bool sent_, ) =  batch_.recipient.call{value: msg.value}("");
            require(sent_, 'TX_FAILED');
        }

        _mintTo(msg.sender, audio_);
        
    }

    function _mintTo(address to_, string memory audio_) private {
        
        _minters[_batch][to_]++;

        _token_ids++;
        _tokens[_token_ids] = IAudioTokens.Token(
            audio_,
            _batch
        );

        _mint(to_, _token_ids);
    }

    function name() public view override returns(string memory){
        return getString('name');
    }

    function symbol() public view override returns(string memory){
        return getString('symbol');
    }

    function updateTokenAudio(uint token_id_, string memory audio_) public onlyHolder(token_id_) {
        string memory oldUri = _tokens[token_id_].audio;
        _tokens[token_id_].audio = audio_;
        emit AudioUpdated(token_id_, oldUri, audio_);
    }

    function getToken(uint token_id_) public view returns(IAudioTokens.Token memory){
        return _tokens[token_id_];
    }

    function tokenURI(uint token_id_) public view override returns(string memory) {
        require(token_id_ <= _token_ids, 'TOKEN_DOES_NOT_EXIST');
        return IMeta(getAddress('meta')).getMeta(token_id_);
    }

    /// Overrides

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
