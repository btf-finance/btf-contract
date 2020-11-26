// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "../../../interface/IVault.sol";
import "../../../interface/USDT.sol";
import "../../../interface/Curve.sol";

//interface IERC20 {
//    function balanceOf(address account) external view returns (uint256);
//
//    function transfer(address recipient, uint256 amount) external returns (bool);
//
//    function allowance(address owner, address spender) external view returns (uint256);
//
//    function approve(address spender, uint256 amount) external returns (bool);
//
//    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
//}
//
//interface USDT {
//    function approve(address guy, uint256 wad) external;
//
//    function transfer(address _to, uint256 _value) external;
//
//    function transferFrom(address _from, address _to, uint256 _value) external;
//}
//
//interface ICurveFi_4 {
//    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;
//}
//
//interface IVault {
//    function deposit(uint256) external;
//}
//
//library SafeMath {
//    function add(uint256 a, uint256 b) internal pure returns (uint256) {
//        uint256 c = a + b;
//        require(c >= a, "SafeMath: addition overflow");
//
//        return c;
//    }
//}
//
//library Math {
//    function min(uint256 a, uint256 b) internal pure returns (uint256) {
//        return a < b ? a : b;
//    }
//}

contract ToolScrv {
    using SafeMath for uint256;

    address public constant curve = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
    // sCrv
    address public constant want = 0xC25a3A3b969415c80451098fa907EC722572917F;
    // bsCRV
    address public constant bToken = 0x7bD9EFcA0eA682CC455456dC6eA9f1774a7667c9;

    // stablecoins
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant susd = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;

    event Recycled(address indexed user, uint256 sentDai, uint256 sentUsdc, uint256 sentUsdt,
        uint256 sentSusd, uint256 sentWant, uint256 receivedBToken);

    constructor() public {
        IERC20(dai).approve(curve, uint256(- 1));
        IERC20(usdc).approve(curve, uint256(- 1));
        USDT(usdt).approve(curve, uint256(- 1));
        IERC20(susd).approve(curve, uint256(- 1));
        IERC20(want).approve(bToken, uint256(- 1));
    }

    function recycleExactAmounts(address sender, uint256 _dai, uint256 _usdc, uint256 _usdt, uint256 _susd, uint256 _want) internal {
        if (_dai > 0) {
            IERC20(dai).transferFrom(sender, address(this), _dai);
        }
        if (_usdc > 0) {
            IERC20(usdc).transferFrom(sender, address(this), _usdc);
        }
        if (_usdt > 0) {
            USDT(usdt).transferFrom(sender, address(this), _usdt);
        }
        if (_susd > 0) {
            IERC20(susd).transferFrom(sender, address(this), _susd);
        }
        if (_want > 0) {
            IERC20(want).transferFrom(sender, address(this), _want);
        }

        uint256[4] memory depositAmounts = [_dai, _usdc, _usdt, _susd];
        if (_usdc.add(_usdt).add(_susd).add(_dai) > 0) {
            ICurveFi_4(curve).add_liquidity(depositAmounts, 0);
        }

        uint256 wantBalance = IERC20(want).balanceOf(address(this));
        if (wantBalance > 0) {
            IVault(bToken).deposit(wantBalance);
        }

        uint256 _bToken = IERC20(bToken).balanceOf(address(this));
        if (_bToken > 0) {
            IERC20(bToken).transfer(sender, _bToken);
        }

        assert(IERC20(bToken).balanceOf(address(this)) == 0);

        emit Recycled(sender, _dai, _usdc, _usdt, _susd, _want, _bToken);
    }

    function recycle() external {
        uint256 _dai = Math.min(IERC20(dai).balanceOf(msg.sender), IERC20(dai).allowance(msg.sender, address(this)));
        uint256 _usdc = Math.min(IERC20(usdc).balanceOf(msg.sender), IERC20(usdc).allowance(msg.sender, address(this)));
        uint256 _usdt = Math.min(IERC20(usdt).balanceOf(msg.sender), IERC20(usdt).allowance(msg.sender, address(this)));
        uint256 _susd = Math.min(IERC20(susd).balanceOf(msg.sender), IERC20(susd).allowance(msg.sender, address(this)));
        uint256 _want = Math.min(IERC20(want).balanceOf(msg.sender), IERC20(want).allowance(msg.sender, address(this)));

        recycleExactAmounts(msg.sender, _dai, _usdc, _usdt, _susd, _want);
    }


    function recycleExact(uint256 _dai, uint256 _usdc, uint256 _usdt, uint256 _susd, uint256 _want) external {
        recycleExactAmounts(msg.sender, _dai, _usdc, _usdt, _susd, _want);
    }
}
