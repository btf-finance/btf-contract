pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interface/IController.sol";
import "../interface/IStrategy.sol";
import "../interface/IStakingRewards.sol";
import "../interface/UniswapRouterV2.sol";

contract StrategyUniEthDaiLp {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Staking rewards address for ETH/DAI LP providers
    address public constant rewards = 0xa1484C3aa22a66C62b77E0AE78E15258bd0cB711;

    // want eth/dai lp tokens
    address public constant want = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11;

    // tokens we're farming
    address public constant uni = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    // stablecoins
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    // weth
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // dex
    address public univ2Router2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Fees 5% in total
    // - 1.5%   keepUNI for development fund
    // - 2%     performanceFee for community fund
    // - 1.5%   used to burn/repurchase btfs
    uint256 public keepUNI = 150;
    uint256 public constant keepUNIMax = 10000;

    uint256 public performanceFee = 200;
    uint256 public constant performanceMax = 10000;

    uint256 public burnFee = 150;
    uint256 public constant burnMax = 10000;

    uint256 public withdrawalFee = 0;
    uint256 public constant withdrawalMax = 10000;

    address public governance;
    address public controller;
    address public strategist;
    address public timelock;
    address public btf;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock,
        address _btf
    ) public {
        governance = _governance;
        strategist = _strategist;
        controller = _controller;
        timelock = _timelock;
        btf = _btf;
    }

    // **** Views ****

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public view returns (uint256) {
        return IStakingRewards(rewards).balanceOf(address(this));
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function getName() external pure returns (string memory) {
        return "StrategyUniEthDaiLp";
    }

    function getHarvestable() external view returns (uint256) {
        return IStakingRewards(rewards).earned(address(this));
    }

    // **** Setters ****

    function setKeepUNI(uint256 _keepUNI) external {
        require(msg.sender == governance, "!governance");
        keepUNI = _keepUNI;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        withdrawalFee = _withdrawalFee;
    }

    function setPerformanceFee(uint256 _performanceFee) external {
        require(msg.sender == governance, "!governance");
        performanceFee = _performanceFee;
    }

    function setBurnFee(uint256 _burnFee) external {
        require(msg.sender == governance, "!governance");
        burnFee = _burnFee;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setTimelock(address _timelock) external {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    // **** State Mutations ****

    function deposit() public {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(rewards, 0);
            IERC20(want).approve(rewards, _want);
            IStakingRewards(rewards).stake(_want);
        }
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    // Contoller only function for withdrawing for free
    // This is used to swap between vaults
    function freeWithdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        IERC20(want).safeTransfer(msg.sender, _amount);
    }

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        if (withdrawalFee > 0) {
            uint256 _fee = _amount.mul(withdrawalFee).div(withdrawalMax);
            IERC20(want).safeTransfer(IController(controller).comAddr(), _fee);
            _amount = _amount.sub(_fee);
        }

        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault");
        // additional protection so we don't burn the funds

        IERC20(want).safeTransfer(_vault, _amount);
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault");
        // additional protection so we don't burn the funds
        IERC20(want).safeTransfer(_vault, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        IStakingRewards(rewards).withdraw(_amount);
        return _amount;
    }

    function brine() public {
        harvest();
    }

    function harvest() public {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects UNI tokens
        IStakingRewards(rewards).getReward();
        uint256 _uni = IERC20(uni).balanceOf(address(this));
        if (_uni > 0) {
            // 10% is locked up for future gov
            if (keepUNI > 0) {
                uint256 _keepUNI = _uni.mul(keepUNI).div(keepUNIMax);
                IERC20(uni).safeTransfer(
                    IController(controller).devAddr(),
                    _keepUNI
                );
                _uni = _uni.sub(_keepUNI);
            }

            _swap(uni, weth, _uni);
        }

        // Swap half WETH for DAI
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0) {
            // Burn some btfs first
            if (burnFee > 0) {
                uint256 _burnFee = _weth.mul(burnFee).div(burnMax);
                _swap(weth, btf, _burnFee);
                IERC20(btf).transfer(
                    IController(controller).burnAddr(),
                    IERC20(btf).balanceOf(address(this))
                );
                _weth = _weth.sub(_burnFee);
            }

            _swap(weth, dai, _weth.div(2));
        }

        // Adds in liquidity for ETH/DAI
        _weth = IERC20(weth).balanceOf(address(this));
        uint256 _dai = IERC20(dai).balanceOf(address(this));
        if (_weth > 0 && _dai > 0) {
            IERC20(weth).safeApprove(univ2Router2, 0);
            IERC20(weth).safeApprove(univ2Router2, _weth);

            IERC20(dai).safeApprove(univ2Router2, 0);
            IERC20(dai).safeApprove(univ2Router2, _dai);

            UniswapRouterV2(univ2Router2).addLiquidity(
                weth,
                dai,
                _weth,
                _dai,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(weth).transfer(
                IController(controller).comAddr(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(dai).transfer(
                IController(controller).comAddr(),
                IERC20(dai).balanceOf(address(this))
            );
        }

        // We want to get back UNI ETH/DAI LP tokens
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            // Performance fee
            if (performanceFee > 0) {
                IERC20(want).safeTransfer(
                    IController(controller).comAddr(),
                    _want.mul(performanceFee).div(performanceMax)
                );
            }

            deposit();
        }
    }

    // Emergency function call
    function execute(address _target, bytes memory _data)
    public
    payable
    returns (bytes memory response)
    {
        require(msg.sender == timelock, "!timelock");

        require(_target != address(0), "!target");

        // call contract in current context
        assembly {
            let succeeded := delegatecall(
            sub(gas(), 5000),
            _target,
            add(_data, 0x20),
            mload(_data),
            0,
            0
            )
            let size := returndatasize()

            response := mload(0x40)
            mstore(
            0x40,
            add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
            // throw if delegatecall failed
                revert(add(response, 0x20), size)
            }
        }
    }

    // **** Internal functions ****
    function _swap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        // Swap with uniswap
        IERC20(_from).safeApprove(univ2Router2, 0);
        IERC20(_from).safeApprove(univ2Router2, _amount);

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

        UniswapRouterV2(univ2Router2).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }
}

