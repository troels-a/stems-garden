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
    let price = '0';

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

        const Stems = await hre.ethers.getContractFactory("AudioTokens");
        contract = await Stems.deploy();
        const Meta = await hre.ethers.getContractFactory("Meta");
        const meta = await Meta.deploy();

        // // Polly things
        // const Polly = await hre.ethers.getContractFactory('Polly');
        // polly = (await Polly.attach('0x756df61a905e68A82f4D4eCA3bD1DB17D0E9423E')).connect(pollyOwner);
        
        // await expect(polly.updateModule('Stems Garden', implementation.address))
        // .to.emit(polly, 'moduleUpdated');

        // await polly.connect(owner).createConfig('Stems Garden', [
        //     ['Stems Garden', 1, nullAddress]
        // ]);

        // const configs = await polly.getConfigsForOwner(owner.address);
        // const config = await polly.getConfig(configs[0]);
        // contract = Stems.attach(config.modules[0].location);

        await contract.connect(owner).setAddress('meta', meta.address);
        await contract.connect(owner).setString('name', 'Stems Garden');
        await contract.connect(owner).setString('symbol', 'STEM');

        minter1 = await contract.connect(wallet1);
        minter2 = await contract.connect(wallet2);
        minter3 = await contract.connect(wallet3);
        preview = new Preview(contract.connect(owner));
        
    });


    it('no batch', async function(){

        expect(await contract.batchAvailable()).to.be.false;

    });

        
    it('owner can create batch', async function(){
        const ownerContract = contract.connect(owner);
        await ownerContract.createBatch(url1, 50, oneDay, hre.ethers.utils.parseEther(price), owner.address);
        const batch = await ownerContract.getBatch(await ownerContract.currentBatchIndex());
        expect(await contract.getAvailable()).to.equal(50);
    })


    it('batch should be closed', async function(){

        await expect(minter1.mint(url1, {value: hre.ethers.utils.parseEther(price)})).to.be.revertedWith('BATCH_UNAVAILABLE');
        expect(await minter1.batchAvailable()).to.be.false;

    })


    it('batch should be open for minting after set time', async function(){

        await network.provider.send("evm_increaseTime", [oneDay*2]);
        await network.provider.send("evm_mine");

        await expect(minter1.mint(url1, {value: hre.ethers.utils.parseEther('100')})).to.be.revertedWith('INVALID_VALUE');

        await minter1.mint(url1, {value: hre.ethers.utils.parseEther(price)});
        await minter2.mint(url2, {value: hre.ethers.utils.parseEther(price)});
        await minter3.mint(url3, {value: hre.ethers.utils.parseEther(price)});

        const stem1 = await contract.getToken(10001);
        const stem2 = await contract.getToken(10002);
        const stem3 = await contract.getToken(10003);

        expect(stem1.audio).to.equal(url1);
        expect(stem2.audio).to.equal(url2);
        expect(stem3.audio).to.equal(url3);

    });


    it('new batch can be created before first is over', async function(){
        
        const ownerContract = contract.connect(owner);
        await ownerContract.createBatch(url2, 100, 0, hre.ethers.utils.parseEther(price)*2, owner.address);
        const batch = await ownerContract.getBatch(await ownerContract.currentBatchIndex());
        expect(await contract.getAvailable()).to.equal(100);

    })


    it('max mint limit can be set and unset', async function(){
        const ownerContract = contract.connect(owner);

        await ownerContract.setUint('max_mints', 3);
        await minter1.mint(url1);
        await minter1.mint(url1);
        await minter1.mint(url1);
        
        await expect(minter1.mint(url1)).to.be.revertedWith('MINT_THRESHOLD_EXCEEDED');
        
        await ownerContract.setUint('max_mints', 0);
        
        await minter1.mint(url1)

    })


    it('can mint max tokens', async function(){
        
        this.timeout(1000*240);

        const avail = await contract.getAvailable();
        let i = 1;
        while(i <= avail){
            await minter3.mint(url1, {value: hre.ethers.utils.parseEther(price)*2});
            i++;
        }
        console.log(i);

        await expect(minter3.mint(url1, {value: hre.ethers.utils.parseEther(price)*2})).to.be.revertedWith('BATCH_UNAVAILABLE');

    });


    it('generate json', async function(){
        await preview.writeJSON(10001);
        await preview.writeJSON(10002);
        await preview.writeJSON(10003);
        await preview.writeJSON(20001);
        await preview.writeJSON(20002);
        await preview.writeJSON(20003);
    });


});