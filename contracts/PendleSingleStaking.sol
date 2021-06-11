//SPDX-License-Identifier: MIT
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
pragma solidity 0.7.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./PendleWrapper.sol";


contract PendleSingleStaking is PendleWrapper, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public starttime;
    uint256 public duration;
    uint256 public periodFinish;
    uint256 public lastUpdateTime;
    uint256 public remainingPendleRewards;
    uint256 public rewardPerBlock;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward, uint256 duration);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardReinvested(address indexed user, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    modifier checkStart() {
        require(block.timestamp >= starttime, "not started");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(uint256 _starttime) {
        starttime = _starttime;
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    function notifyRewardAmountAndDuration(uint256 _reward, uint256 _duration)
        external
        onlyOwner
        updateReward(address(0))
    {
        duration = _duration;

        if (block.timestamp > starttime) {
            if (block.timestamp >= periodFinish) {
                remainingPendleRewards = _reward;
                rewardPerBlock = remainingPendleRewards.div(duration);
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardPerBlock);
                remainingPendleRewards = _reward.add(leftover);
                rewardPerBlock = remainingPendleRewards.div(duration);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(duration);
            emit RewardAdded(_reward, _duration);
        } else {
            remainingPendleRewards = _reward;
            rewardPerBlock = _reward.div(duration);
            lastUpdateTime = starttime;
            periodFinish = starttime.add(duration);
            emit RewardAdded(_reward, _duration);
        }

        pendle.safeTransferFrom(msg.sender, address(this), _reward);
    }

    function claimReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            remainingPendleRewards = remainingPendleRewards.sub(reward);
            pendle.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function reinvestReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            super.stake(reward);
            rewards[msg.sender] = 0;
            emit RewardReinvested(msg.sender, reward);
        }
    }

    /*
     * @dev stake() visibility is public as overriding PendleWrapper's stake() function
     */
    function stake(uint256 amount) public override updateReward(msg.sender) checkStart {
        require(amount > 0, "cannot stake 0");
        super.stake(amount);

        // transfer token last, to follow CEI pattern
        pendle.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /*
     * @dev withdraw() visibility is public as overriding PendleWrapper's withdraw() function
     */
    function withdraw(uint256 amount) public override updateReward(msg.sender) checkStart {
        require(amount > 0, "cannot withdraw 0");
        super.withdraw(amount);

        // transfer token last, to follow CEI pattern
        pendle.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalPendleStaked() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardPerBlock).mul(1e18).div(
                    totalPendleStaked()
                )
            );
    }
}
