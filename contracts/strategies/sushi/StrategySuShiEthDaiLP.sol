// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./StrategySuShiLPBase.sol";

contract StrategySuShiEthDaiLP is StrategySuShiLPBase {

    // Token addresses
    uint256 public pId = 2;
    address public daiSlp = 0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f;
    address public daiToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    constructor(
        address _btf,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategySuShiLPBase(
        pId,
        daiSlp,
        daiToken,
        _btf,
        _governance,
        _strategist,
        _controller,
        _timelock
    ){}

    function getName() external override pure returns (string memory) {
        return "StrategySuShiEthDaiLP";
    }
}
