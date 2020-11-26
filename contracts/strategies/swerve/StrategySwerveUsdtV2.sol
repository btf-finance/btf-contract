pragma solidity ^0.6.2;

import "./StrategySwerveBase.sol";

contract StrategySwerveUsdtV2 is StrategySwerveBase {
    constructor(
        address _btf,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategySwerveBase(_btf, 2, _governance, _strategist, _controller, _timelock)
    {
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySwerveUsdtV2";
    }
}

