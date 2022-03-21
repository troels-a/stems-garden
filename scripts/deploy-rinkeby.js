const hre = require("hardhat");
const networkName = hre.network.name;
require("colors");

function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

async function main() {

  if(networkName !== 'rinkeby'){
    console.log(`NOT RINKEBY! ${networkName.toUpperCase()} DETECTED`.bgRed)
    throw '';
  }

  console.log('DEPLOYING TO RINKEBY'.bgGreen);

  const FileTokens = await hre.ethers.getContractFactory("FileTokens");
  const fileTokens = await FileTokens.deploy();
  await fileTokens.deployed();
  const Meta = await hre.ethers.getContractFactory("Meta");
  const meta = await Meta.deploy();
  await meta.deployed()

  await fileTokens.setAddress('meta', meta.address);
  await fileTokens.setString('name', 'Stems Garden');
  await fileTokens.setString('symbol', 'STEM');
  await fileTokens.setString('s1_title', 'Dirt Speaks Truth');

  console.log("FileTokens.sol deployed to:", fileTokens.address.green.bold);
  console.log("Meta deployed to:", meta.address.green.bold);
  
  
  console.log('waiting to verify contracts...'.bgBlue);
  await sleep(120000);

  console.log('Verifying contracts'.bgBlue);
  
  await hre.run("verify:verify", {
    address: fileTokens.address,
    contract: 'contracts/FileTokens.sol:FileTokens'
  });

  await hre.run("verify:verify", {
    address: meta.address,
    contract: 'contracts/Meta.sol:Meta'
  });

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
