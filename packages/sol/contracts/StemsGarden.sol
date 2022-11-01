// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@polly-tools/core/contracts/Polly.sol";
import "@polly-tools/module-token721/contracts/Token721.sol";
import "@polly-tools/module-json/contracts/Json.sol";
import "@polly-tools/module-token-utils/contracts/TokenUtils.sol";
import "@polly-tools/module-royalty-info/contracts/RoyaltyInfo.sol";


interface JsonGenerator {
    function json(address parent_, uint id_) external view returns (string memory);
}

interface ImageGenerator {
    function image(address parent_, uint id_) external view returns (string memory);
}


contract MutableTokens is PMReadOnly, PollyTokenAux {

    Json public immutable _json;
    TokenUtils public immutable _utils;

    string public constant override PMNAME = "MutableTokens";
    uint public constant override PMVERSION = 1;
    
    string[] private _hooks = [
        "beforeCreateToken",
        "beforeMint721",
        "tokenURI"
    ];

    constructor(address polly_address_) {

        _setConfigurator(address(new MutableTokensConfigurator()));

        Polly polly_ = Polly(polly_address_);

        _json = Json(
        polly_
        .getModule('Json', 1)
        .implementation
        );

        _utils = TokenUtils(
        polly_
        .getModule('TokenUtils', 1)
        .implementation
        );

    }

    function hooks() public view override returns (string[] memory) {
        return _hooks;
    }

    
    function _stringIsEmpty(string memory string_) private pure returns (bool) {
        return keccak256(abi.encodePacked(string_)) == keccak256(abi.encodePacked(''));
    }


    function beforeCreateToken(address, uint id_, PollyToken.MetaEntry[] memory meta_) public pure override returns(uint, PollyToken.MetaEntry[] memory){
        require(meta_.length > 0, 'EMPTY_META');
        return (id_, meta_);
    }

    function beforeMint721(address parent_, uint id_, bool pre_, PollyAux.Msg memory msg_) public view override {
        require(PollyToken(parent_).tokenExists(id_), 'TOKEN_NOT_FOUND');
        if(!pre_){
            _utils.requireValidTime(parent_, id_);
            _utils.requireValidPrice721(parent_, id_, msg_._value);
        }
    }


    function _prefix(string memory string_) private pure returns (string memory){
        return string(abi.encodePacked('MutableTokens.', string_));
    }

    
    function getTokenMeta(address token721_address_, uint id_, string memory key_) public view returns (Polly.Param memory) {
        Token721 token_ = Token721(token721_address_);
        return token_.getMetaHandler().get(id_, _prefix(key_));
    }


    function setTokenMeta(address token721_address_, uint id_, string memory key_, Polly.Param memory value_) public {
        Token721 token_ = Token721(token721_address_);
        require(token_.tokenExists(id_), 'TOKEN_NOT_FOUND');
        require(token_.ownerOf(id_) == msg.sender, 'NOT_OWNER');
        token_.getMetaHandler().set(id_, _prefix(key_), value_);
    }


    function getTokenImage(address parent_, uint id_) public view returns (string memory){
        
        Meta meta_ = PollyToken(parent_).getMetaHandler();
        if(meta_.getAddress(0, 'Token/image_generator') != address(0))
            return ImageGenerator(meta_.getAddress(0, 'Token/image_generator')).image(parent_, id_);
        
        return meta_.getString(id_, 'Token/image');

    }


    function tokenURI(address parent_, uint id_) public view override returns (string memory) {

        require(PollyToken(parent_).tokenExists(id_), 'TOKEN_NOT_FOUND');

        Meta meta_ = PollyToken(parent_).getMetaHandler();

        if(meta_.getAddress(0, 'json_generator') != address(0))
            return JsonGenerator(meta_.getAddress(0, 'json_generator')).json(parent_, id_);

        Json.Item[] memory items_ = new Json.Item[](3);

        items_[0]._type = Json.Type.STRING;
        items_[0]._key = 'name';
        items_[0]._string = meta_.getString(id_, 'Token/name');

        items_[1]._type = Json.Type.STRING;
        items_[1]._key = 'description';
        items_[1]._string = meta_.getString(id_, 'Token/description');

        items_[2]._type = Json.Type.STRING;
        items_[2]._key = 'image';
        items_[2]._string = getTokenImage(parent_, id_);


        return _json.encode(items_, Json.Format.OBJECT);

    }


}


contract MutableTokensConfigurator is PollyConfigurator {

    function inputs() public pure override returns (string[] memory) {

        string[] memory inputs_ = new string[](4);
        
        inputs_[0] = "string || Name || Name of the garden";
        inputs_[1] = "string || Symbol || Symbol of the garden";
        inputs_[2] = "uint || Max stems || Maximum number of stems";

        return inputs_;

    }


    function outputs() public pure override returns (string[] memory) {

        string[] memory outputs_ = new string[](2);
        
        outputs_[0] = "module || Token721 || Address of the Token721 module";
        outputs_[1] = "module || Meta || Address of the Meta module";

        return outputs_;

    }

    function fee(Polly, address, Polly.Param[] memory) public pure override returns (uint) {
        return 0.001 ether;
    }

    function run(Polly polly_, address for_, Polly.Param[] memory params_) public override payable returns(Polly.Param[] memory) {

        require(params_.length == inputs().length, 'INVALID_PARAMS_COUNT');
        Polly.Param[] memory rparams_ = new Polly.Param[](outputs().length);

        MutableTokens mt_ = MutableTokens(polly_.getModule('MutableTokens', 1).implementation);
        RoyaltyInfo ri_ = RoyaltyInfo(polly_.getModule('RoyaltyInfo', 1).implementation);

        Polly.Param[] memory token_params_ = new Polly.Param[](4);
        token_params_[0]._address = address(mt_);
        token_params_[1]._address = address(ri_);

        Polly.Param[] memory token_config_ = Polly(polly_).configureModule(
            'Token721',
            1,
            token_params_,
            false,
            ''
        );

        Token721 token_ = Token721(token_config_[0]._address);

        Meta meta_ = token_.getMetaHandler();
        meta_.setString(0, 'Token/name', params_[0]._string);
        meta_.setString(0, 'Token/symbol', params_[1]._string);
        meta_.setString(0, 'MutableTokens/uri', params_[2]._string);
        meta_.setUint(0, 'Token/max_supply', params_[3]._uint);

        meta_.grantRole('manager', address(mt_)); // Allows the MutableTokens module to set meta on Meta. Neccesarry for setMeta function to work.
        
        // Transfer to for_
        _transfer(token_config_[0]._address, for_); // transfer PollyToken module
        _transfer(token_config_[1]._address, for_); // transfer Meta module

        rparams_[0] = token_config_[0]; // return the token module
        rparams_[1] = token_config_[1]; // return Meta module

        return rparams_;

    }

}
