import { BigNumber as BN, utils, Contract, Wallet, providers } from 'ethers';

import { StakingPendleFixture, stakingPendleFixture } from './fixtures/pendle.fixture';

import {
  consts,
  Scenario,
  generateRandomScenario,
  minerStart,
  minerStop,
  evm_snapshot,
  mineBlock,
  getCurrentBlock,
  evm_revert,
  calculateStakingResult,
  approxBigNumber,
} from './helpers';

const { waffle } = require('hardhat');
const { loadFixture } = waffle;

describe('SingleStakingManager', function () {
  let pdl: Contract;
  let stakingContract: Contract;
  let stakingManager: Contract;

  const wallets = waffle.provider.getWallets();
  const [alice, bob, charlie, dave, eve] = wallets;

  let snapshotId: string;
  let globalSnapshotId: string;

  async function buildTestEnv() {
    let fixture: StakingPendleFixture = await loadFixture(stakingPendleFixture);
    pdl = fixture.pdl;
    stakingContract = fixture.stakingContract;
    stakingManager = fixture.stakingManager;
  }

  async function distributeTokenEvenly(): Promise<void> {
    const amount: BN = (await pdl.balanceOf(alice.address)).div(2);
    for (let person of [eve, stakingManager]) {
      await pdl.connect(alice).transfer(person.address, amount);
    }
  }

  async function mineToBlock(blockNumber: number): Promise<void> {
    while ((await getCurrentBlock()) <= blockNumber) {
      await mineBlock();
    }
  }

  before(async () => {
    await buildTestEnv();
    globalSnapshotId = await evm_snapshot();
    snapshotId = await evm_snapshot();
  });

  beforeEach(async () => {
    await evm_revert(snapshotId);
    snapshotId = await evm_snapshot();
    await distributeTokenEvenly();
  });

  after(async () => {
    await evm_revert(globalSnapshotId);
  });

  it('Staking PENDLE tests', async function () {
    let finishedDistToBlock: BN = await stakingManager.finishedDistToBlock();
    let rewardPerBlock: BN = await stakingManager.rewardPerBlock();

    let scenario = await generateRandomScenario(rewardPerBlock, 100, finishedDistToBlock, [alice, bob, charlie, dave]);
    let resultReward = await calculateStakingResult(scenario, rewardPerBlock, finishedDistToBlock, [
      alice,
      bob,
      charlie,
      dave,
    ]);

    for (let action of scenario) {
      let block: BN = action.blockId;
      let newRewardPerBlock: BN = action.rewardPerBlock;
      let userId: number = action.userId;
      let user = wallets[userId];
      let stakingAction: number = action.stakingAction;
      let amount: BN = action.amount;

      await mineToBlock(block.toNumber() - 2);

      await minerStop();
      if (!newRewardPerBlock.eq(rewardPerBlock)) {
        await stakingManager.adjustRewardPerBlock(newRewardPerBlock, consts.HG);
        rewardPerBlock = newRewardPerBlock;
      }

      if (stakingAction == 0) {
        await pdl.connect(eve).transfer(user.address, amount, consts.HG);
        await pdl.connect(user).approve(stakingContract.address, amount);
        await stakingContract.connect(user).enter(amount, consts.HG);
      } else {
        await stakingContract.connect(user).leave(amount, consts.HG);
      }
      await mineBlock();
      await minerStart();
    }

    for (let i = 0; i < 4; ++i) {
      approxBigNumber(await pdl.balanceOf(wallets[i].address), resultReward[i], 10, false);
    }
  });
});
