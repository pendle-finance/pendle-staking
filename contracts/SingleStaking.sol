// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SingleStakingManager.sol";

contract SingleStaking {
    event Enter(address user, uint256 pendleAmount, uint256 shares);
    event Leave(address user, uint256 pendleAmount, uint256 shares);

    using SafeMath for uint256;
    IERC20 public immutable rewardToken;
    SingleStakingManager public immutable stakingManager;
    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    constructor(IERC20 _rewardToken) {
        rewardToken = _rewardToken;
        stakingManager = SingleStakingManager(msg.sender);
    }

    // Locks Pendle, update the user's shares (non-transferable)
    function enter(uint256 _amount) public returns (uint256 sharesToMint) {
        // Before doing anything, get the unclaimed rewards first
        stakingManager.distributeRewards();
        // Gets the amount of Pendle locked in the contract
        uint256 totalRewardToken = rewardToken.balanceOf(address(this));
        // Gets the amount of shares in existence
        uint256 totalShares = totalSupply;
        // If no shares exists, mint it 1:1 to the amount put in

        if (totalShares == 0 || totalRewardToken == 0) {
            sharesToMint = _amount;
        }
        // Calculate and mint the amount of shares the Pendle is worth. The ratio will change overtime, as shares is burned/minted and Pendle distributed to this contract
        else {
            sharesToMint = _amount.mul(totalShares).div(totalRewardToken);
        }
        _mint(msg.sender, sharesToMint);
        // Lock the Pendle in the contract
        rewardToken.transferFrom(msg.sender, address(this), _amount);
        emit Enter(msg.sender, _amount, sharesToMint);
    }

    // Unlocks the staked + gained Pendle and burns shares
    function leave(uint256 _share) public returns (uint256 rewards) {
        // Before doing anything, get the unclaimed rewards first
        stakingManager.distributeRewards();
        // Gets the amount of shares in existence
        uint256 totalShares = totalSupply;
        // Calculates the amount of Pendle the shares is worth
        rewards = _share.mul(rewardToken.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        rewardToken.transfer(msg.sender, rewards);
        emit Leave(msg.sender, rewards, _share);
    }

    function _mint(address user, uint256 amount) internal {
        balances[user] = balances[user].add(amount);
        totalSupply = totalSupply.add(amount);
    }

    function _burn(address user, uint256 amount) internal {
        balances[user] = balances[user].sub(amount);
        totalSupply = totalSupply.sub(amount);
    }
}
