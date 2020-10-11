pragma solidity ^0.6.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interface/IStrategy.sol";
import "../interface/IVault.sol";
import "../interface/Converter.sol";
import "../interface/IStrategyConverter.sol";
import "../interface/OneSplitAudit.sol";


contract Controller is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant burn = 0x000000000000000000000000000000000000dEaD;
    address public onesplit = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;

    address public governance;
    address public strategist;
    address public timelock;

    // community fund
    address public comAddr;
    // development fund
    address public devAddr;
    // burn or repurchase
    address public burnAddr;
    mapping(address => address) public vaults;
    mapping(address => address) public strategies;
    mapping(address => mapping(address => address)) public converters;
    mapping(address => mapping(address => address)) public strategyConverters;

    mapping(address => mapping(address => bool)) public approvedStrategies;

    uint256 public split = 500;
    uint256 public constant max = 10000;

    constructor(
        address _governance,
        address _strategist,
        address _comAddr, // should be the multisig
        address _devAddr,
        address _burnAddr, //should be the multisig
        address _timelock
    ) public {
        governance = _governance;
        strategist = _strategist;
        comAddr = _comAddr;
        devAddr = _devAddr;
        burnAddr = _burnAddr;
        timelock = _timelock;
    }

    function setComAddr(address _comAddr) public {
        require(msg.sender == governance, "!governance");
        comAddr = _comAddr;
    }

    function setDevAddr(address _devAddr) public {
        require(msg.sender == governance || msg.sender == devAddr, "!governance");
        devAddr = _devAddr;
    }

    function setBurnAddr(address _burnAddr) public {
        require(msg.sender == governance, "!governance");
        burnAddr = _burnAddr;
    }

    function setStrategist(address _strategist) public {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setSplit(uint256 _split) public {
        require(msg.sender == governance, "!governance");
        split = _split;
    }

    function setOneSplit(address _onesplit) public {
        require(msg.sender == governance, "!governance");
        onesplit = _onesplit;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setTimelock(address _timelock) public {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }

    function setVault(address _token, address _vault) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!strategist"
        );
        require(vaults[_token] == address(0), "vault");
        vaults[_token] = _vault;
    }

    function approveStrategy(address _token, address _strategy) public {
        require(msg.sender == timelock, "!timelock");
        approvedStrategies[_token][_strategy] = true;
    }

    function revokeStrategy(address _token, address _strategy) public {
        require(msg.sender == governance, "!governance");
        approvedStrategies[_token][_strategy] = false;
    }

    function setConverter(
        address _input,
        address _output,
        address _converter
    ) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!strategist"
        );
        converters[_input][_output] = _converter;
    }

    function setStrategyConverter(
        address[] memory stratFrom,
        address[] memory stratTo,
        address _stratConverter
    ) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!strategist"
        );

        for (uint256 i = 0; i < stratFrom.length; i++) {
            for (uint256 j = 0; j < stratTo.length; j++) {
                strategyConverters[stratFrom[i]][stratTo[j]] = _stratConverter;
            }
        }
    }

    function setStrategy(address _token, address _strategy) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!strategist"
        );
        require(approvedStrategies[_token][_strategy] == true, "!approved");

        address _current = strategies[_token];
        if (_current != address(0)) {
            IStrategy(_current).withdrawAll();
        }
        strategies[_token] = _strategy;
    }

    function earn(address _token, uint256 _amount) public {
        address _strategy = strategies[_token];
        address _want = IStrategy(_strategy).want();
        if (_want != _token) {
            address converter = converters[_token][_want];
            IERC20(_token).safeTransfer(converter, _amount);
            _amount = Converter(converter).convert(_strategy);
            IERC20(_want).safeTransfer(_strategy, _amount);
        } else {
            IERC20(_token).safeTransfer(_strategy, _amount);
        }
        IStrategy(_strategy).deposit();
    }

    function balanceOf(address _token) external view returns (uint256) {
        return IStrategy(strategies[_token]).balanceOf();
    }

    function withdrawAll(address _token) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!strategist"
        );
        IStrategy(strategies[_token]).withdrawAll();
    }

    function inCaseTokensGetStuck(address _token, uint256 _amount) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!governance"
        );
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    function inCaseStrategyTokenGetStuck(address _strategy, address _token)
    public
    {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!governance"
        );
        IStrategy(_strategy).withdraw(_token);
    }

    function getExpectedReturn(
        address _strategy,
        address _token,
        uint256 parts
    ) public view returns (uint256 expected) {
        uint256 _balance = IERC20(_token).balanceOf(_strategy);
        address _want = IStrategy(_strategy).want();
        (expected,) = OneSplitAudit(onesplit).getExpectedReturn(
            _token,
            _want,
            _balance,
            parts,
            0
        );
    }

    // Only allows to withdraw non-core strategy tokens ~ this is over and above normal yield
    function yearn(
        address _strategy,
        address _token,
        uint256 parts
    ) public {
        require(
            msg.sender == strategist || msg.sender == governance,
            "!governance"
        );
        // This contract should never have value in it, but just incase since this is a public call
        uint256 _before = IERC20(_token).balanceOf(address(this));
        IStrategy(_strategy).withdraw(_token);
        uint256 _after = IERC20(_token).balanceOf(address(this));
        if (_after > _before) {
            uint256 _amount = _after.sub(_before);
            address _want = IStrategy(_strategy).want();
            uint256[] memory _distribution;
            uint256 _expected;
            _before = IERC20(_want).balanceOf(address(this));
            IERC20(_token).safeApprove(onesplit, 0);
            IERC20(_token).safeApprove(onesplit, _amount);
            (_expected, _distribution) = OneSplitAudit(onesplit).getExpectedReturn(_token, _want, _amount, parts, 0);
            OneSplitAudit(onesplit).swap(
                _token,
                _want,
                _amount,
                _expected,
                _distribution,
                0
            );
            _after = IERC20(_want).balanceOf(address(this));
            if (_after > _before) {
                _amount = _after.sub(_before);
                uint256 _reward = _amount.mul(split).div(max);
                earn(_want, _amount.sub(_reward));
                IERC20(_want).safeTransfer(comAddr, _reward);
            }
        }
    }

    function withdraw(address _token, uint256 _amount) public {
        require(msg.sender == vaults[_token], "!vault");
        IStrategy(strategies[_token]).withdraw(_amount);
    }

    // Swaps between vaults
    // Note: This is supposed to be called
    //       by a user if they'd like to swap between vaults w/o the 0.5% fee
    function userSwapVault(
        address _fromToken,
        address _toToken,
        uint256 _pAmount // Pickling token amount to convert
    ) public nonReentrant returns (uint256) {
        address _fromVault = vaults[_fromToken];
        address _toVault = vaults[_toToken];

        address _fromStrategy = strategies[_fromToken];
        address _toStrategy = strategies[_toToken];


        address _strategyConverter = strategyConverters[_fromStrategy][_toStrategy];

        require(_strategyConverter != address(0), "!strategy-converter");

        // 1. Transfers bVault tokens from msg.sender
        IVault(_fromVault).transferFrom(msg.sender, address(this), _pAmount);

        // 2. Get amount of tokens to transfer from strategy to burn
        // Note: this token amount is the LP token
        uint256 _fromTokenAmount = IVault(_fromVault).getRatio().mul(_pAmount).div(
            1e18
        );

        // If we don't have enough funds in the strategy
        // We'll deposit funds from the vault to the strategy
        // Note: This assumes that no single person is responsible
        //       for 100% of the liquidity.
        // If this a single person is 100% responsible for the liquidity
        // we can simply set min = max in vaults
        if (IStrategy(_fromStrategy).balanceOf() < _fromTokenAmount) {
            IVault(_fromVault).earn();
        }

        // 3. Withdraw tokens from strategy and burns pToken
        IVault(_fromVault).transfer(burn, _pAmount);
        IStrategy(_fromStrategy).freeWithdraw(_fromTokenAmount);

        // 4. Converts to Token
        IERC20(_fromToken).approve(_strategyConverter, _fromTokenAmount);
        IStrategyConverter(_strategyConverter).convert(
            msg.sender,
            _fromToken,
            _toToken,
            _fromTokenAmount
        );

        // 5. Deposits into BFTVault
        uint256 _toTokenAmount = IERC20(_toToken).balanceOf(address(this));
        IERC20(_toToken).approve(_toVault, _toTokenAmount);
        IVault(_toVault).deposit(_toTokenAmount);

        // 6. Sends msg.sender all the btf vault tokens
        uint256 _retPAmount = IVault(_toVault).balanceOf(address(this));
        IVault(_toVault).transfer(
            msg.sender,
            _retPAmount
        );

        return _retPAmount;
    }
}

