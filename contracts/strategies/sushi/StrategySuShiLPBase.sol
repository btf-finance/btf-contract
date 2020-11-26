// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../StrategyBase.sol";
import "../../interface/ISuShiMaster.sol";

abstract contract StrategySuShiLPBase is StrategyBase {

    uint256 public poolId;

    // WETH/<pariToken> pair
    address public want;
    address public pariToken;
    ISuShiMaster public iSuShiMaster;

    // Token addresses
    address public sushi = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address public sushiSwapRouterV2 = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    
    constructor(
        uint256 _poolId,
        address _want, // Sushiswap's LP Token / Pair token
        address _pariToken, // Sushi pair token like DAI/USDC/USDT/TUSD
        address _btf,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBase(_btf, _want, _governance, _strategist, _controller, _timelock) {
        require(_pariToken != address(0), "ex");

        want = _want;
        pariToken = _pariToken;

        iSuShiMaster = ISuShiMaster(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);

        //Check lp token
        address _lpt;
        (_lpt,,,) = iSuShiMaster.poolInfo(_poolId);
        require(_lpt == _want, "Pool Info does not match lp token");
        poolId = _poolId;
    }

    function balanceOfPool() public override view returns (uint256) {
        (uint256 bal,) = iSuShiMaster.userInfo(poolId, address(this));
        return bal;
    }

    function getHarvestAble() external view returns (uint256) {
        return iSuShiMaster.pendingSushi(poolId, address(this));
    }

    function harvest() public override onlyBenevolent {
        // Claim reward from sushiMaster
        iSuShiMaster.withdraw(poolId, 0);
        uint256 _sushiBal = IERC20(sushi).balanceOf(address(this));

        if (_sushiBal > 0) {
            // Swap sushi token to weth token
            _sushiSwap(sushi, weth, _sushiBal);
        }

        // Swap half WETH for pair token
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
            if (_weth > 0) {
                _sushiSwap(weth, pariToken, _weth.div(2));
            }
        }

        uint256 _afterWeth = IERC20(weth).balanceOf(address(this));
        uint256 _pariToken = IERC20(pariToken).balanceOf(address(this));

        if (_afterWeth > 0 && _pariToken > 0) {
            IERC20(weth).safeApprove(sushiSwapRouterV2, 0);
            IERC20(weth).safeApprove(sushiSwapRouterV2, _afterWeth);

            IERC20(pariToken).safeApprove(sushiSwapRouterV2, 0);
            IERC20(pariToken).safeApprove(sushiSwapRouterV2, _pariToken);

            UniswapRouterV2(sushiSwapRouterV2).addLiquidity(
                weth,
                pariToken,
                _afterWeth,
                _pariToken,
                0,
                0,
                address(this),
                now + 60
            );
        }

        // We want to get back UNI LP tokens
        deposit();
    }

    function deposit() public override {
        uint256 _wantBal = IERC20(want).balanceOf(address(this));
        if (_wantBal > 0) {
            IERC20(want).safeApprove(address(iSuShiMaster), 0);
            IERC20(want).safeApprove(address(iSuShiMaster), _wantBal);
            iSuShiMaster.deposit(poolId, _wantBal);
        }
    }

    // Token swap A to B
    function _sushiSwap(address _from, address _to, uint256 _amount) internal {
        require(_to != address(0));

        // Swap with uniswap
        IERC20(_from).safeApprove(sushiSwapRouterV2, 0);
        IERC20(_from).safeApprove(sushiSwapRouterV2, _amount);

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        UniswapRouterV2(sushiSwapRouterV2).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        iSuShiMaster.withdraw(poolId, _amount);
        return _amount;
    }
}