// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../StrategyBase.sol";
import "../../interface/Curve.sol";
import "./StrategyCurveBase.sol";

interface IKeepRewardsClaimable {
    function claim_rewards() external;
}

contract StrategyCurveTBTCMixedV1 is StrategyCurveBase {
    // Curve stuff
    address public _tBTCMixed = 0x64eda51d3Ad40D56b9dFc5554E06F94e1Dd786Fd;
    address public _gauge = 0x6828bcF74279eE32f2723eC536c22c51Eed383C6;
    // tbtc pool
    address public _curve = 0xaa82ca713D94bBA7A89CEAB55314F9EfFEdDc78c;
    address public _mintr = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
    // keep
    address public keep = 0x85Eee30c52B0b379b046Fb0F85F4f3Dc3009aFEC;
    address public keepRewards = 0x6828bcF74279eE32f2723eC536c22c51Eed383C6;

    constructor(
        address _btf,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public
    StrategyCurveBase(_tBTCMixed, _gauge, _curve, _mintr, _btf, _governance, _strategist, _controller, _timelock)
    {
    }

    // **** Views ****

    function getMostPremium()
    public
    pure
    returns (address, uint256)
    {
        return (wbtc, 2);
    }

    function getName() external override pure returns (string memory) {
        return "StrategyCurveTBTCMixedV1";
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
        // this also sends KEEP to keepRewards contract
        ICurveMintr(mintr).mint(gauge);
        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
            _swapUniswap(crv, weth, _crv);
        }

        IKeepRewardsClaimable(keepRewards).claim_rewards();
        uint256 _keep = IERC20(keep).balanceOf(address(this));
        if (_keep >0) {
            _swapUniswap(keep, weth, _keep);
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
            uint256[4] memory liquidity;
            liquidity[toIndex] = _to;
            ICurveFi_4(curve).add_liquidity(liquidity, 0);
        }

        // get back want (Curve.fi tBTC/sbtcCrv)
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            deposit();
        }
    }
}
