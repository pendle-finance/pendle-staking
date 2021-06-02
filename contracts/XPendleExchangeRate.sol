//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

contract xPendleExchangeRate {
    IERC20 private immutable xPendle;
    IERC20 private immutable pendle;

    constructor(IERC20 _xPendle, IERC20 _pendle) public {
        xPendle = _xPendle;
        pendle = _pendle;
    }

    function getExchangeRate() public view returns (uint256) {
        return (pendle.balanceOf(address(xPendle)) * 1e18) / xPendle.totalSupply();
    }

    function toPENDLE(uint256 xPendleAmount) public view returns (uint256 pendleAmount) {
        pendleAmount = (xPendleAmount * pendle.balanceOf(address(xPendle))) / xPendle.totalSupply();
    }

    function toXPENDLE(uint256 pendleAmount) public view returns (uint256 xPendleAmount) {
        xPendleAmount = (pendleAmount * xPendle.totalSupply()) / pendle.balanceOf(address(xPendle));
    }
}
