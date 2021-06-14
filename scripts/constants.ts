import { BigNumber as BN } from 'ethers';

const ONE_E_18 = BN.from(10).pow(18);

export const consts = {
  ONE_E_18,
  INF: BN.from(2).pow(256).sub(1),
  PENDLE: '0x808507121b80c02388fad14726482e061b8da827',
  REWARD_PER_BLOCK: ONE_E_18.mul(66209).div(100000),
  START_BLOCK: 12633000
};
