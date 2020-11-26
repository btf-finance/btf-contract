// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./StrategySuShiLPBase.sol";

contract StrategySuShiEthUsdcLP is StrategySuShiLPBase {

    // Token addresses
    uint256 public pId = 1;
    address public usdcSlp = 0x397FF1542f962076d0BFE58eA045FfA2d347ACa0;
    address public usdcToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    constructor(
        address _btf,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategySuShiLPBase(
        pId,
        usdcSlp,
        usdcToken,
        _btf,
        _governance,
        _strategist,
        _controller,
        _timelock
    ){}

    function getName() external override pure returns (string memory) {
        return "StrategySuShiEthUsdcLP";
    }
}
