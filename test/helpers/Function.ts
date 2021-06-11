import { BigNumber as BN, utils, Contract, Wallet, providers } from 'ethers';
import { randomBN, randomNumber } from './Numeric';

const { waffle } = require('hardhat');

/// If rewardPerBlock is changed, blockToWait should be at least 1
export interface Scenario{
    blockId: BN,
    rewardPerBlock: BN,
    userId: number,
    stakingAction: number, /// 0 is enter, 1 is leave
    amount: BN
};

export async function generateRandomScenario(startRewardPerBlock: BN, nTest: Number, firstBlock: BN, wallets: Wallet[]): Promise<Scenario[]> {
    let fixedAmount = BN.from(1000000);
    let scenario: Scenario[] = [];
    let amountEntered: BN[] = [];
    let rewardPerBlock = startRewardPerBlock;

    for(let i = 0; i < wallets.length; ++i) {
        amountEntered.push(BN.from(0));
    }

    let currentBlock = firstBlock;

    for(let i = 0; i < nTest; ++i) {
        currentBlock = currentBlock.add(1 + randomNumber(5));
        if (randomNumber(5) == 0) {
            rewardPerBlock = rewardPerBlock.div(2).add(randomBN(rewardPerBlock));
        }
        let userId = randomNumber(wallets.length);

        let stakingAction = randomNumber(2);
        if (amountEntered[userId].eq(0)) {
            stakingAction = 0;
        }
        
        let amount = fixedAmount.div(2).add(randomBN(fixedAmount));
        if (stakingAction == 1) {
            amount = randomBN(amountEntered[userId].div(1000));
        }

        scenario.push({
            blockId: currentBlock,
            rewardPerBlock,
            userId,
            stakingAction,
            amount
        });

        if (stakingAction == 0){
            amountEntered[userId] = amountEntered[userId].add(amount);
        }
        else {
            amountEntered[userId] = amountEntered[userId].sub(amount);
        }
    }

    return scenario;
}

export async function calculateStakingResult(scenario: Scenario[], startRewardPerBlock: BN, firstBlock: BN, wallets: Wallet[]): Promise<BN[]> {
    
    let totalLp = BN.from(0);
    let totalReward = BN.from(0);
    let resultLp: BN[] = [];
    for(let i = 0; i < wallets.length; ++i) {
        resultLp.push(BN.from(0));
    }

    let resultReward: BN[] = [];
    for(let i = 0; i < wallets.length; ++i) {
        resultReward.push(BN.from(0));
    }

    let lastBlock: BN = firstBlock;
    let rewardLastBlock: BN = startRewardPerBlock;

    for(let action of scenario) {
        let block: BN = action.blockId;
        let rewardPerBlock: BN = action.rewardPerBlock;
        let userId: number = action.userId;
        let stakingAction: number = action.stakingAction;
        let amount: BN = action.amount; 
        
        while(lastBlock.lt(block)) {
            lastBlock = lastBlock.add(1);
            totalReward = totalReward.add(rewardLastBlock);
        }

        rewardLastBlock = rewardPerBlock;
        if (stakingAction == 0) {
            if (totalLp.gt(0)) {
                let amountLp: BN = totalLp.mul(amount).div(totalReward);
                resultLp[userId] = resultLp[userId].add(amountLp);
                totalLp = totalLp.add(amountLp);
            } else {
                resultLp[userId] = amount;
                totalLp = totalLp.add(amount);
            }
            totalReward = totalReward.add(amount);            
        } else {
            let amountReward: BN = totalReward.mul(amount).div(totalLp);
            resultLp[userId] = resultLp[userId].sub(amount);
            totalLp = totalLp.sub(amount);
            resultReward[userId] = resultReward[userId].add(amountReward);
            totalReward = totalReward.sub(amountReward);
        }
    }

    return resultReward;
}