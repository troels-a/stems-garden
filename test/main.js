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

        const Stems = await hre.ethers.getContractFactory("Stems");
        contract = await Stems.deploy();
        [owner, wallet1, wallet2, wallet3] = await hre.ethers.getSigners();

        minter1 = await contract.connect(wallet1);
        minter2 = await contract.connect(wallet2);
        minter3 = await contract.connect(wallet3);
        preview = new Preview(contract);
        
    });

        
    it('owner can mint and pass', async function(){
        await contract.mint(url1, wallet1.address);

        let left = await contract.timeLeft();
        left = left.toNumber();
        console.log(toDays(left));
        expect(await contract.next()).to.equal(wallet1.address);
        expect(left).to.be.greaterThan(0);

    })

    it('time left should decrease', async function(){

        let left = await contract.timeLeft();
        left = left.toNumber();

        await network.provider.send("evm_increaseTime", [oneDay*5]);
        await network.provider.send("evm_mine");

        let newLeft = await contract.timeLeft();
        newLeft = newLeft.toNumber();

        console.log(toDays(left), toDays(newLeft));

        expect(newLeft).to.be.lessThan(left);
        
    })

    it('only delegated should be able to mint', async function(){
       
        await expect(minter3.mint(url2, wallet2.address)).to.be.revertedWith('NOT_NEXT');

    });

    it('user1 can mint and pass', async function(){

        await minter1.mint(url2, wallet2.address);

        let left = await contract.timeLeft();
        left = left.toNumber();
        
        expect(await contract.next()).to.equal(wallet2.address);
        expect(left).to.be.greaterThan(oneDay*6);
        
    })


    it('on timeout owner can redelegate', async function(){
       
        await network.provider.send("evm_increaseTime", [oneDay*7]);
        await network.provider.send("evm_mine");

        let left = await contract.timeLeft();
        left = left.toNumber();

        
        expect(left).to.equal(0);
        await expect(minter1.delegateNext(wallet1.address)).to.be.revertedWith('Ownable: caller is not the owner');

        await contract.delegateNext(wallet2.address);
        expect(await contract.next()).to.equal(wallet2.address);
        left = await contract.timeLeft();
        left = left.toNumber();
        expect(left).to.be.greaterThan(oneDay*6)

    });


    it('user2 can mint and pass', async function(){

        await minter2.mint(url3, wallet3.address);

        let left = await contract.timeLeft();
        left = left.toNumber();
        
        expect(await contract.next()).to.equal(wallet3.address);
        expect(left).to.be.greaterThan(0);
        
    })


    it('generate json', async function(){
        await preview.writeJSON(1);
        await preview.writeJSON(2);
        await preview.writeJSON(3);
    });


});