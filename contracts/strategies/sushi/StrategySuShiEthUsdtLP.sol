// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./StrategySuShiLPBase.sol";

contract StrategySuShiEthUsdtLP is StrategySuShiLPBase {

    // Token addresses
    uint256 public pId = 0;
    address public usdtSlp = 0x06da0fd433C1A5d7a4faa01111c044910A184553;
    address public usdtToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor(
        address _btf,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategySuShiLPBase(
        pId,
        usdtSlp,
        usdtToken,
        _btf,
        _governance,
        _strategist,
        _controller,
        _timelock
    ){}

    function getName() external override pure returns (string memory) {
        return "StrategySuShiEthUsdtLP";
    }
}
