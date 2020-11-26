// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./StrategyCmpdBase.sol";

import "../../interface/IVault.sol";
import "../../interface/IController.sol";
import "../../interface/Compound.sol";
import "../../interface/UniswapRouterV2.sol";
import "../../lib/Exponential.sol";

contract StrategyCmpdDaiV1 is StrategyCmpdBase {
    address public constant cdai = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    constructor(
        address _btf,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public StrategyCmpdBase(_btf, dai, cdai, _governance, _strategist, _controller, _timelock)
    {
    }

    // **** Views **** //

    function getName() external override pure returns (string memory) {
        return "StrategyCmpdDaiV1";
    }
}
