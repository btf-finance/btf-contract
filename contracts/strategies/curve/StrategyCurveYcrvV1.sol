// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../StrategyBase.sol";
import "../../interface/Curve.sol";
import "../../interface/yVault.sol";
import "./StrategyCurveBase.sol";

contract StrategyCurveYcrvV1 is StrategyCurveBase {
    // Curve stuff
    address public _ycrv = 0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8;
    address public _gauge = 0xFA712EE4788C042e2B7BB55E6cb8ec569C4530c1;
    // y pool
    address public _curve = 0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51;
    address public _mintr = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;

    // y
    address public yDai = 0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01;

    constructor(
        address _btf,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public
    StrategyCurveBase(_ycrv, _gauge, _curve, _mintr, _btf, _governance, _strategist, _controller, _timelock)
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
        return "StrategyCurveYcrvV1";
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

            yCurveFromDai();
        }

        // get back want (3crv)
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            deposit();
        }
    }

    /**
    * Converts all DAI to yCRV using the CRV protocol.
    */
    function yCurveFromDai() internal {
        uint256 daiBalance = IERC20(dai).balanceOf(address(this));
        if (daiBalance > 0) {
            IERC20(dai).safeApprove(yDai, 0);
            IERC20(dai).safeApprove(yDai, daiBalance);
            yERC20(yDai).deposit(daiBalance);
        }
        uint256 yDaiBalance = IERC20(yDai).balanceOf(address(this));
        if (yDaiBalance > 0) {
            IERC20(yDai).safeApprove(curve, 0);
            IERC20(yDai).safeApprove(curve, yDaiBalance);
            // we can accept 0 as minimum, this will be called only by trusted roles
            uint256 minimum = 0;
            ICurveFi_4(curve).add_liquidity([yDaiBalance, 0, 0, 0], minimum);
        }
        // now we have yCRV
    }
}
