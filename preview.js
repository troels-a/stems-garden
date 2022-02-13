const fs = require('fs');
const path = require('path').dirname(__dirname);

class Preview {


    constructor(contract){
        this.contract = contract;
    }

    async writeSVG(tokenId){
        let svg = await this.contract.getSVG(tokenId, false, true);
        const svgDir = `./preview`;
        svg = Buffer.from(svg.replace(/^data\:image\/svg\+xml\;base64\,/, ''), 'base64').toString('utf-8');
        await fs.promises.mkdir(svgDir, { recursive: true }).catch(console.error);
        await fs.writeFileSync(`${svgDir}/${tokenId}.svg`, svg, {flag: 'w'});
    }

    async writeJSON(tokenId){
        let json = await this.contract.tokenURI(tokenId);
        const jsonDir = `./preview`;
        json = JSON.stringify(JSON.parse(Buffer.from(json.replace(/^data\:application\/json\;base64\,/, ''), 'base64').toString('utf-8')), null, 2)
        await fs.promises.mkdir(jsonDir, { recursive: true }).catch(console.error);
        await fs.writeFileSync(`${jsonDir}/${tokenId}.json`, json, {flag: 'w'});
    }
    
    async getMetaData(tokenId){
        let metadata = await this.contract.tokenURI(tokenId);
        metadata = Buffer.from(metadata.replace(/^data\:application\/json\;base64\,/, ''), 'base64');
        metadata = metadata.toString('utf-8');
        return JSON.parse(metadata);
    }


}

module.exports = Preview;