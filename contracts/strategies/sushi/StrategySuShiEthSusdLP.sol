// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./StrategySuShiLPBase.sol";

contract StrategySuShiEthSUsdLP is StrategySuShiLPBase {

    // Token addresses
    uint256 public pId = 3;
    address public sUSDSlp = 0xF1F85b2C54a2bD284B1cf4141D64fD171Bd85539;
    address public sUSDToken = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;

    constructor(
        address _btf,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategySuShiLPBase(
        pId,
        sUSDSlp,
        sUSDToken,
        _btf,
        _governance,
        _strategist,
        _controller,
        _timelock
    ){}

    function getName() external override pure returns (string memory) {
        return "StrategySuShiEthSusdLP";
    }
}
