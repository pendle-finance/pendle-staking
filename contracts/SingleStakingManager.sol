// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SingleStaking.sol";

contract SingleStakingManager is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable rewardToken;
    address public immutable stakingContract;

    uint256 public rewardPerBlock;
    uint256 public lastDistributedBlock;

    constructor(IERC20 _rewardToken, uint256 _rewardPerBlock) {
        require(address(_rewardToken) != address(0), "ZERO_ADDRESS");
        require(_rewardPerBlock != 0, "ZERO_REWARD_PER_BLOCK");
        rewardToken = _rewardToken;
        stakingContract = address(new SingleStaking(_rewardToken));
        lastDistributedBlock = block.number;
    }

    function distributeRewards() external {
        require(msg.sender == stakingContract, "NOT_STAKING_CONTRACT");
        _distributeRewardsInternal();
    }

    function adjustRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        _distributeRewardsInternal(); // distribute until the latest block first

        rewardPerBlock = _rewardPerBlock;
    }

    function getBlocksLeft() public view returns (uint256 blocksLeft) {
        uint256 currentRewardBalance = rewardToken.balanceOf(address(this));
        blocksLeft = currentRewardBalance.div(rewardPerBlock);
    }

    // Distribute the rewards to the staking contract, until the latest block, or until we run out of rewards
    function _distributeRewardsInternal() internal {
        uint256 blocksToDistribute = min(block.number.sub(lastDistributedBlock), getBlocksLeft());
        lastDistributedBlock += blocksToDistribute;

        rewardToken.safeTransfer(stakingContract, blocksToDistribute.mul(rewardPerBlock));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
