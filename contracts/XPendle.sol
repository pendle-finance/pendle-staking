// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract XPendle is ERC20("Pependle", "xPENDLE"){
    using SafeMath for uint256;
    IERC20 public pendle;

    constructor(IERC20 _pendle) public {
        pendle = _pendle;
    }

    // Locks Pendle and mints xPendle
    function enter(uint256 _amount) public {
        // Gets the amount of Pendle locked in the contract
        uint256 totalPendle = pendle.balanceOf(address(this));
        // Gets the amount of xPendle in existence
        uint256 totalShares = totalSupply();
        // If no xPendle exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalPendle == 0) {
            _mint(msg.sender, _amount);
        } 
        // Calculate and mint the amount of xPendle the Pendle is worth. The ratio will change overtime, as xPendle is burned/minted and Pendle deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalPendle);
            _mint(msg.sender, what);
        }
        // Lock the Pendle in the contract
        pendle.transferFrom(msg.sender, address(this), _amount);
    }

    // Unlocks the staked + gained Pendle and burns xPendle
    function leave(uint256 _share) public {
        // Gets the amount of xPendle in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of Pendle the xPendle is worth
        uint256 what = _share.mul(pendle.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        pendle.transfer(msg.sender, what);
    }
}
