pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interface/IController.sol";
import "../interface/IStrategy.sol";
import "../interface/Gauge.sol";
import "../interface/ISwerveFi.sol";
import "../interface/UniswapRouterV2.sol";

contract StrategySwerve {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // gauge of swerve
    address public constant rewards = 0xb4d0C929cD3A1FbDc6d57E7D3315cF0C4d6B4bFa;

    // swUSD lp tokens
    address public constant want = 0x77C6E4a580c0dCE4E5c7a17d0bc077188a83A059;

    // tokens we're farming
    address public constant swrv = 0xB8BAa0e4287890a5F79863aB62b7F175ceCbD433;

    // swusdv2 pool
    address public constant curve = 0x329239599afB305DA0A2eC69c58F8a6697F9F88d;

    // swerve minter
    address constant public mintr = 0x2c988c3974AD7E604E276AE0294a7228DEf67974;

    // stablecoins
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant tusd = 0x0000000000085d4780B73119b644AE5ecd22b376;

    // weth
    address public constant weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

    // dex
    address public constant univ2Router2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Fees 5% in total
    // - 1.5%   keepSWRV for development fund
    // - 2%     performanceFee for community fund
    // - 1.5%   used to burn/repurchase btfs
    uint256 public keepSWRV = 150;
    uint256 public constant keepSWRVMax = 10000;

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
        return Gauge(rewards).balanceOf(address(this));
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function getName() external pure returns (string memory) {
        return "StrategySwerve";
    }

    function getHarvestable() external returns (uint256) {
        return Gauge(rewards).claimable_tokens(address(this));
    }

    // **** Setters ****

    function setKeepSWRV(uint256 _keepSWRV) external {
        require(msg.sender == governance, "!governance");
        keepSWRV = _keepSWRV;
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

    function getMostPremiumStablecoin() public view returns (address, uint256) {
        uint256[] memory balances = new uint256[](4);
        // DAI
        balances[0] = ISwerveFi(curve).balances(0);
        // USDC
        balances[1] = ISwerveFi(curve).balances(1).mul(10 ** 12);
        // USDT
        balances[2] = ISwerveFi(curve).balances(2).mul(10 ** 12);
        // TUSD
        balances[3] = ISwerveFi(curve).balances(3);

        // DAI
        if (
            balances[0] < balances[1] &&
            balances[0] < balances[2] &&
            balances[0] < balances[3]
        ) {
            return (dai, 0);
        }

        // USDC
        if (
            balances[1] < balances[0] &&
            balances[1] < balances[2] &&
            balances[1] < balances[3]
        ) {
            return (usdc, 1);
        }

        // USDT
        if (
            balances[2] < balances[0] &&
            balances[2] < balances[1] &&
            balances[2] < balances[3]
        ) {
            return (usdt, 2);
        }

        // TUSD
        if (
            balances[3] < balances[0] &&
            balances[3] < balances[1] &&
            balances[3] < balances[2]
        ) {
            return (tusd, 3);
        }

        // If they're somehow equal, we just want DAI
        return (dai, 0);
    }

    // **** State Mutations ****

    function deposit() public {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(rewards, 0);
            IERC20(want).approve(rewards, _want);
            Gauge(rewards).deposit(_want);
        }
    }

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        require(swrv != address(_asset), "swrv");

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
        Gauge(rewards).withdraw(_amount);
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

        // stablecoin we want to convert to
        (address to, uint256 toIndex) = getMostPremiumStablecoin();

        // Collects SWRV tokens
        Mintr(mintr).mint(rewards);
        uint256 _swrv = IERC20(swrv).balanceOf(address(this));
        if (_swrv > 0) {
            // 10% is locked up for future gov
            if (keepSWRV > 0) {
                uint256 _keepSWRV = _swrv.mul(keepSWRV).div(keepSWRVMax);
                IERC20(swrv).safeTransfer(
                    IController(controller).devAddr(),
                    _keepSWRV
                );
                _swrv = _swrv.sub(_keepSWRV);
            }

            _swap(swrv, to, _swrv);
        }

        uint256 _to = IERC20(to).balanceOf(address(this));
        if (_to > 0) {
            // Burn some btfs first
            if (burnFee > 0) {
                uint256 _burnFee = _to.mul(burnFee).div(burnMax);
                _swap(to, btf, _burnFee);
                IERC20(btf).transfer(
                    IController(controller).burnAddr(),
                    IERC20(btf).balanceOf(address(this))
                );
                _to = _to.sub(_burnFee);
            }
        }

        // Adds in liquidity for swusdv2 pool to get back want (swusd)
        if (_to > 0) {
            IERC20(to).safeApprove(curve, 0);
            IERC20(to).safeApprove(curve, _to);
            uint256[4] memory liquidity;
            liquidity[toIndex] = _to;
            ISwerveFi(curve).add_liquidity(liquidity, 0);
        }

        // We want to get back swrv
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            // 4.5% rewards gets sent to treasury
            IERC20(want).safeTransfer(
                IController(controller).comAddr(),
                _want.mul(performanceFee).div(performanceMax)
            );

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

    /**
    * Creates a Swerve lock
    */
    function createLock(address lockToken, address escrow, uint256 value, uint256 unlockTime) public {
        require(msg.sender == governance, "!governance");
        IERC20(lockToken).safeApprove(escrow, 0);
        IERC20(lockToken).safeApprove(escrow, value);
        VotingEscrow(escrow).create_lock(value, unlockTime);
    }

    /**
    * Checkpoints the Swerve lock balance
    */
    function checkpoint(address _gauge) public {
        require(msg.sender == governance, "!governance");
        Gauge(_gauge).user_checkpoint(address(this));
    }

    /**
    * Increases the lock amount for Swerve
    */
    function increaseAmount(address lockToken, address escrow, uint256 value) public {
        require(msg.sender == governance, "!governance");
        IERC20(lockToken).safeApprove(escrow, 0);
        IERC20(lockToken).safeApprove(escrow, value);
        VotingEscrow(escrow).increase_amount(value);
    }

    /**
    * Increases the unlock time for Swerve
    */
    function increaseUnlockTime(address escrow, uint256 unlock_time) public {
        require(msg.sender == governance, "!governance");
        VotingEscrow(escrow).increase_unlock_time(unlock_time);
    }

    /**
    * Withdraws an expired lock
    */
    function withdrawLock(address lockToken, address escrow) public {
        require(msg.sender == governance, "!governance");
        uint256 balanceBefore = IERC20(lockToken).balanceOf(address(this));
        VotingEscrow(escrow).withdraw();
        uint256 balanceAfter = IERC20(lockToken).balanceOf(address(this));
        if (balanceAfter > balanceBefore) {
            IERC20(lockToken).safeTransfer(msg.sender, balanceAfter.sub(balanceBefore));
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

