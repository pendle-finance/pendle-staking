import TestPENDLE from '../../build/artifacts/contracts/tokens/TestPENDLE.sol/TestPENDLE.json';
import SingleStaking from '../../build/artifacts/contracts/SingleStaking.sol/SingleStaking.json'
import SingleStakingManager from '../../build/artifacts/contracts/SingleStakingManager.sol/SingleStakingManager.json'
import { 
  BigNumber as BN, 
  utils, Contract, 
  Wallet, 
  providers 
} from 'ethers';
import { 
  consts, 
  getCurrentBlock
} from '../helpers';

const { waffle } = require('hardhat');
const { deployContract, provider } = waffle;


export interface StakingPendleFixture {
  pdl: Contract,
  stakingManager: Contract,
  stakingContract: Contract
};

export async function stakingPendleFixture(_: Wallet[],
    provider: providers.Web3Provider
): Promise<StakingPendleFixture> {
  const wallets = waffle.provider.getWallets();
  const [alice, bob, charlie, dave, eve] = wallets;
  const pdl: Contract = await deployContract(alice, TestPENDLE, [
      "Pendle",
      "PENDLE",
      18
    ],
    consts.HG
  );

  const stakingManager: Contract = await deployContract(alice, SingleStakingManager, [
      pdl.address,
      10000,
      (await provider.getBlockNumber()) + 10
    ],
    consts.HG 
  );

  const stakingContract: Contract = new Contract(await stakingManager.stakingContract(), SingleStaking.abi, alice);

  return { pdl, stakingManager, stakingContract }
}