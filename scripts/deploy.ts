import hre from 'hardhat';
import { consts } from './constants';

async function main() {
  const Manager = await hre.ethers.getContractFactory('SingleStakingManager');
  const [deployer] = await hre.ethers.getSigners();
  // const currentBlock = await hre.ethers.provider.getBlockNumber();

  console.log(`\t deployer = ${deployer.address}`);
  console.log(`\t consts.PENDLE = ${consts.PENDLE}`);
  console.log(`\t consts.REWARD_PER_BLOCK = ${consts.REWARD_PER_BLOCK}`);
  console.log(`\t consts.START_BLOCK = ${consts.START_BLOCK}`);

  const manager = await Manager.deploy(consts.PENDLE, consts.REWARD_PER_BLOCK, consts.START_BLOCK);
  await manager.deployed();

  console.log('SingleStakingManager deployed to:', manager.address);
  console.log(`stakingContract = ${await manager.stakingContract()}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
