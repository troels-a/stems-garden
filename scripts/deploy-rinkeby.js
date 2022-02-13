const hre = require("hardhat");
const networkName = hre.network.name;
require("colors");

async function main() {

  if(networkName !== 'rinkeby'){
    console.log(`NOT RINKEBY! ${networkName.toUpperCase()} DETECTED`.bgRed)
    throw '';
  }

  console.log('DEPLOYING TO RINKEBY'.bgGreen);

  const Stems = await hre.ethers.getContractFactory("Stems");
  const stems = await Stems.deploy();
  await stems.deployed();

  console.log("stems deployed to:", stems.address.green.bold);
  
  [owner, user1, user2, user3] = await hre.ethers.getSigners();

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
