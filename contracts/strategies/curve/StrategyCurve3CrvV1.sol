// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../StrategyBase.sol";
import "../../interface/Curve.sol";
import "../compound/StrategyCmpdBase.sol";
import "./StrategyCurveBase.sol";

contract StrategyCurve3CrvV1 is StrategyCurveBase {
    // Curve stuff
    address public _3crv = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public _gauge = 0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A;
    // 3pool
    address public _curve = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address public _mintr = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;

    constructor(
        address _btf,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public
    StrategyCurveBase(_3crv, _gauge, _curve, _mintr, _btf, _governance, _strategist, _controller, _timelock)
    {
    }

    // **** Views ****

    function getMostPremium()
    public
    view
    returns (address, uint256)
    {
        uint256[] memory balances = new uint256[](3);
        // DAI
        balances[0] = ICurveFi_3(curve).balances(0);
        // USDC
        balances[1] = ICurveFi_3(curve).balances(1).mul(10 ** 12);
        // USDT
        balances[2] = ICurveFi_3(curve).balances(2).mul(10 ** 12);

        // DAI
        if (
            balances[0] < balances[1] &&
            balances[0] < balances[2]
        ) {
            return (dai, 0);
        }

        // USDC
        if (
            balances[1] < balances[0] &&
            balances[1] < balances[2]
        ) {
            return (usdc, 1);
        }

        // USDT
        if (
            balances[2] < balances[0] &&
            balances[2] < balances[1]
        ) {
            return (usdt, 2);
        }

        // If they're somehow equal, we just want DAI
        return (dai, 0);
    }

    function getName() external override pure returns (string memory) {
        return "StrategyCurve3CrvV1";
    }

    // **** State Mutation functions ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // stablecoin we want to convert to
        (address to, uint256 toIndex) = getMostPremium();

        // Collects crv tokens
        // Don't bother voting in v1
        ICurveMintr(mintr).mint(gauge);
        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
            _swapUniswap(crv, weth, _crv);
        }

        // Adds liquidity to curve.fi's pool
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0) {
            if (devFundFee > 0) {
                uint256 _devFundFee = _weth.mul(devFundFee).div(devFundMax);
                IERC20(weth).transfer(
                    IController(controller).devAddr(),
                    _devFundFee
                );
            }

            // Burn some btfs first
            if (burnFee > 0) {
                uint256 _burnFee = _weth.mul(burnFee).div(burnMax);
                _swapUniswap(getSwapPathOfBtf(), _burnFee);
                IERC20(btf).transfer(
                    IController(controller).burnAddr(),
                    IERC20(btf).balanceOf(address(this))
                );
            }

            if (comFundFee > 0) {
                uint256 _comFundFee = _weth.mul(comFundFee).div(comFundMax);
                IERC20(weth).transfer(
                    IController(controller).comAddr(),
                    _comFundFee
                );
            }

            _weth = IERC20(weth).balanceOf(address(this));
            _swapUniswap(weth, to, _weth);

            uint256 _to = IERC20(to).balanceOf(address(this));
            IERC20(to).safeApprove(curve, 0);
            IERC20(to).safeApprove(curve, _to);
            uint256[3] memory liquidity;
            liquidity[toIndex] = _to;
            ICurveFi_3(curve).add_liquidity(liquidity, 0);
        }

        // get back want (3crv)
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            deposit();
        }
    }
}
