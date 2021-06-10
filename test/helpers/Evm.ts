import { BigNumber as BN } from 'ethers';

const hre = require('hardhat');
const { waffle } = require('hardhat');
const { provider } = waffle;

export async function evm_snapshot(): Promise<string> {
  return await hre.network.provider.request({
    method: 'evm_snapshot',
    params: [],
  });
}

export async function mineBlock() {
  await provider.send('evm_mine', []);
}

export async function getCurrentBlock() {
  return (await provider.getBlockNumber());
}

export async function minerStart() {
  await provider.send('evm_setAutomine', [true]);
}

export async function minerStop() {
  await provider.send('evm_setAutomine', [false]);
}

export async function evm_revert(snapshotId: string) {
  return await hre.network.provider.request({
    method: 'evm_revert',
    params: [snapshotId],
  });
}