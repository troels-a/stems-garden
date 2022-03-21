const hre = require("hardhat");
const networkName = hre.network.name;
require("colors");

async function main() {

  if(networkName !== 'mainnet'){
    console.log(`NOT MAINNET! ${networkName.toUpperCase()} DETECTED`.bgRed)
    throw '';
  }

  console.log('DEPLOYING TO MAINNET'.bgGreen);

  const Stems = await hre.ethers.getContractFactory("StemsGarden");
  const stems = await Stems.deploy();
  await stems.deployed();
  const Meta = await hre.ethers.getContractFactory("Meta");
  const meta = await Meta.deploy();

  await stems.setAddress('meta', meta.address);
  await stems.setString('name', 'Stems Garden');
  await stems.setString('symbol', 'STEM');

  console.log("Stems garden deployed to:", stems.address.green.bold);
  console.log("- name", await stems.name())
  console.log("- symbol", await stems.symbol())

  console.log("Meta deployed to:", meta.address.green.bold);
  console.log("- meta", await stems.getAddress('meta'))
  
  [owner, user1, user2, user3] = await hre.ethers.getSigners();

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
