// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./StrategyCmpdBase.sol";

contract StrategyCmpdUsdcV1 is StrategyCmpdBase {
    address public constant cusdc = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;

    constructor(
        address _btf,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public StrategyCmpdBase(_btf, usdc, cusdc, _governance, _strategist, _controller, _timelock)
    {
    }

    // **** Views **** //

    function getName() external override pure returns (string memory) {
        return "StrategyCmpdUsdcV1";
    }
}
