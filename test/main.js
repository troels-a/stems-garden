const { expect } = require("chai");
const fs = require('fs');
const path = require('path').dirname(__dirname);
const Preview = require('../preview.js');

const toDays = (seconds) => ((seconds/60)/60)/24;

describe("***stems.sol***", async function(){

    let preview;
    let polly;
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
    const nullAddress = '0x'+'0'.repeat(40);

    it('should deploy', async function () {

        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: ["0x3827014f2236519f1101ae2e136985e0e603be79"]
        });

        await network.provider.send("hardhat_setBalance", [
            "0x3827014f2236519f1101ae2e136985e0e603be79",
            hre.ethers.utils.parseEther('1000').toHexString(),
        ]);

        const pollyOwner = await ethers.getSigner("0x3827014f2236519f1101ae2e136985e0e603be79");

        [owner, wallet1, wallet2, wallet3] = await hre.ethers.getSigners();

        const Stems = await hre.ethers.getContractFactory("StemsGarden");
        const implementation = await Stems.deploy();
        const Meta = await hre.ethers.getContractFactory("Meta");
        const meta = await Meta.deploy();

        // Polly things
        const Polly = await hre.ethers.getContractFactory('Polly');
        polly = (await Polly.attach('0x756df61a905e68A82f4D4eCA3bD1DB17D0E9423E')).connect(pollyOwner);
        
        await expect(polly.updateModule('Stems Garden', implementation.address))
        .to.emit(polly, 'moduleUpdated');

        await polly.connect(owner).createConfig('Stems Garden', [
            ['Stems Garden', 1, nullAddress]
        ]);

        const configs = await polly.getConfigsForOwner(owner.address);
        const config = await polly.getConfig(configs[0]);
        contract = Stems.attach(config.modules[0].location);
        contract.connect(owner).setAddress('meta', meta.address);
        contract.connect(owner).setString('name', 'Stems Garden');
        contract.connect(owner).setString('symbol', 'STEM');

        minter1 = await contract.connect(wallet1);
        minter2 = await contract.connect(wallet2);
        minter3 = await contract.connect(wallet3);
        preview = new Preview(contract.connect(owner));
        
    });


    it('no season', async function(){

        expect(await contract.seasonOpen()).to.be.false;

    });

        
    it('owner can create season', async function(){
        const ownerContract = contract.connect(owner);
        await ownerContract.createSeason(url1, 50, oneDay);
        const season = await ownerContract.getSeason(await ownerContract.currentSeasonIndex());
        expect(season.supply).to.equal(50);
    })


    it('season should be closed', async function(){

        await expect(minter1.mint(url1)).to.be.revertedWith('SEASON_CLOSED');
        expect(await minter1.seasonOpen()).to.be.false;

    })


    it('season should be open for minting after some time', async function(){

        await network.provider.send("evm_increaseTime", [oneDay*2]);
        await network.provider.send("evm_mine");

        await minter1.mint(url1);
        await minter2.mint(url2);
        await minter3.mint(url3);

        const stem1 = await contract.getStem(1001);
        const stem2 = await contract.getStem(1002);
        const stem3 = await contract.getStem(1003);

        expect(stem1.audio).to.equal(url1);
        expect(stem2.audio).to.equal(url2);
        expect(stem3.audio).to.equal(url3);

    });


    it('minter can only mint once per season', async function(){

        await expect(minter1.mint(url1)).to.revertedWith('ALREADY_MINTED_SEASON');

    });


    it('generate json', async function(){
        await preview.writeJSON(1001);
        await preview.writeJSON(1002);
        await preview.writeJSON(1003);
    });


});