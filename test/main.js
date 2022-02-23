const { expect } = require("chai");
const fs = require('fs');
const path = require('path').dirname(__dirname);
const Preview = require('../preview.js');

const toDays = (seconds) => ((seconds/60)/60)/24;

describe("***stems.sol***", async function(){

    let preview;
    let contract;
    let owner;
    let wallet1;
    let wallet2;
    let wallet3;
    let minter1;
    let minter2;
    let minter3;

    const oneDay = 60*60*24;
    const url1 = 'http://url1.com/file1.mp3';
    const url2 = 'http://url2.com/file2.mp3';
    const url3 = 'http://url3.com/file3.mp3';
  
    it('should deploy', async function () {

        const Stems = await hre.ethers.getContractFactory("StemsGarden");
        contract = await Stems.deploy();
        [owner, wallet1, wallet2, wallet3] = await hre.ethers.getSigners();

        minter1 = await contract.connect(wallet1);
        minter2 = await contract.connect(wallet2);
        minter3 = await contract.connect(wallet3);
        preview = new Preview(contract);
        
    });

        
    it('owner can create season', async function(){

        await contract.createSeason(url1, 50, oneDay);
        const season = await contract.getSeason(await contract.currentSeasonIndex());
        expect(season.supply).to.equal(50);

    })


    it('season should be closed', async function(){

        await expect(minter1.mint(url1)).to.be.revertedWith('SEASON_CLOSED');
        expect(await minter1.seasonOpen()).to.be.false;

    })


    it('season should be open for minting', async function(){

        await network.provider.send("evm_increaseTime", [oneDay*2]);
        await network.provider.send("evm_mine");

        await minter1.mint(url1);
        await minter2.mint(url2);
        await minter3.mint(url3);

        const stem1 = await contract.getStem(1);
        const stem2 = await contract.getStem(2);
        const stem3 = await contract.getStem(3);

        expect(stem1.audio).to.equal(url1);
        expect(stem2.audio).to.equal(url2);
        expect(stem3.audio).to.equal(url3);

    });


    it('minter can only mint once per season', async function(){

        await expect(minter1.mint(url1)).to.revertedWith('ALREADY_MINTED_SEASON');

    });


    it('generate json', async function(){
        await preview.writeJSON(1);
        await preview.writeJSON(2);
        await preview.writeJSON(3);
    });


});