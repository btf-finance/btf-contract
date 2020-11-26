// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../StrategyBase.sol";
import "../../interface/Curve.sol";

abstract contract StrategyCurveBase is StrategyBase {
    // Curve stuff
    address public want;
    address public gauge;
    // curve pool
    address public curve;
    address public mintr;

    // bitcoins
    address public constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant renbtc = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;

    // rewards
    address public constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    constructor(
        address _want,
        address _gauge,
        address _curve,
        address _mintr,
        address _btf,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public
    StrategyBase(_btf, _want, _governance, _strategist, _controller, _timelock)
    {
        want = _want;
        gauge = _gauge;
        curve = _curve;
        mintr = _mintr;
    }

    // **** Getters ****

    function balanceOfPool() public override view returns (uint256) {
        return ICurveGauge(gauge).balanceOf(address(this));
    }

    function getHarvestable() external returns (uint256) {
        return ICurveGauge(gauge).claimable_tokens(address(this));
    }

    // **** State Mutation functions ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(gauge, 0);
            IERC20(want).safeApprove(gauge, _want);
            ICurveGauge(gauge).deposit(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
    internal
    override
    returns (uint256)
    {
        ICurveGauge(gauge).withdraw(_amount);
        return _amount;
    }
}
