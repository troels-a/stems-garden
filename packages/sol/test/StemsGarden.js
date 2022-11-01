const { expect, config } = require("chai");
const { ethers } = require("hardhat");
const {parseParams} = require('@polly-tools/core/utils/Polly.js')

/*********************
* CHAINS
*/

describe("Token721 module", async function(){
    
    const nullAddress = '0x'+'0'.repeat(40);
    
    let
    polly,
    token721,
    garden,
    meta,
    json,
    owner,
    user1,
    user2,
    user3,
    minter1,
    minter2,
    minter3
    
    it("Setup", async function(){
        
        [owner, user1, user2, user3] = await ethers.getSigners();
        polly = await hre.polly.deploy(true);

        await hre.polly.addModule('Json');
        await hre.polly.addModule('Meta');
        await hre.polly.addModule('TokenUtils');
        await hre.polly.addModule('RoyaltyInfo');
        await hre.polly.addModule('Token721');
        await hre.polly.addModule('MutableTokens', polly.address);

    })

    it("configure", async function(){
        
        const [, configuration] = await hre.polly.configureModule('MutableTokens', {
            version: 1,
            params: parseParams([
                'StemsGarden',
                'STEMS1',
                10,
                'https://stems.garden/api/'
            ])
        })

        token721 = await hre.ethers.getContractAt('Token721', configuration.params[0]._address);
        meta = await hre.ethers.getContractAt('Meta', await token721.getMetaHandler());

        console.log(await token721.PMNAME())
        console.log(await meta.PMNAME())

    })
    
    
})
