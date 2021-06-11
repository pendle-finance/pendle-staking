require('@nomiclabs/hardhat-ethers');

task('deploy', 'Deploys contracts').setAction(async () => {
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();

  console.log(`Deploying Contracts using ${deployerAddress}`);
  console.log('============================\n');

  const Contract = await ethers.getContractFactory('PendleSingleStaking');
  const instance = await Contract.deploy('1623436200');

  console.log(`Contract: ${instance.address}`);
});
