// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../StrategyBase.sol";
import "../../interface/Curve.sol";
import "../../interface/Compound.sol";
import "./StrategyCurveBase.sol";

contract StrategyCurveCcrvV1 is StrategyCurveBase {
    // Curve stuff
    address public _ccrv = 0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2;
    address public _gauge = 0x7ca5b0a2910B33e9759DC7dDB0413949071D7575;
    // compound pool
    address public _curve = 0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56;
    address public _mintr = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;

    // compound
    address public cDai = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    constructor(
        address _btf,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public
    StrategyCurveBase(_ccrv, _gauge, _curve, _mintr, _btf, _governance, _strategist, _controller, _timelock)
    {
    }

    // **** Views ****

    function getMostPremium()
    public
    pure
    returns (address, uint256)
    {
        return (dai, 0);
    }

    function getName() external override pure returns (string memory) {
        return "StrategyCurveCcrvV1";
    }

    // **** State Mutation functions ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

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
            _swapUniswap(weth, dai, _weth);

            cCurveFromDai();
        }

        // get back want (3crv)
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            deposit();
        }
    }

    /**
* Converts all DAI to cCRV using the CRV protocol.
*/
    function cCurveFromDai() internal {
        uint256 daiBalance = IERC20(dai).balanceOf(address(this));
        if (daiBalance > 0) {
            IERC20(dai).safeApprove(cDai, 0);
            IERC20(dai).safeApprove(cDai, daiBalance);
            require(ICToken(cDai).mint(daiBalance) == 0, "!cDai");
        }
        uint256 cDaiBalance = IERC20(cDai).balanceOf(address(this));
        if (cDaiBalance > 0) {
            IERC20(cDai).safeApprove(curve, 0);
            IERC20(cDai).safeApprove(curve, cDaiBalance);
            // we can accept 0 as minimum, this will be called only by trusted roles
            uint256 minimum = 0;
            ICurveFi_2(curve).add_liquidity([cDaiBalance, 0], minimum);
        }
        // now we have cCRV
    }
}
