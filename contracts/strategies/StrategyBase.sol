pragma solidity ^0.6.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interface/IVault.sol";
import "../interface/IStakingRewards.sol";
import "../interface/UniswapRouterV2.sol";
import "../interface/IController.sol";

// Strategy Contract Basics
abstract contract StrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Fees 30% in total
    // - 0%   devFundFee for development fund
    // - 0%     comFundFee for community fund
    // - 30%   used to burn/repurchase btfs which will be sent to profit pool
    uint256 public devFundFee = 0;
    uint256 public constant devFundMax = 10000;

    uint256 public comFundFee = 0;
    uint256 public constant comFundMax = 10000;

    uint256 public burnFee = 3000;
    uint256 public constant burnMax = 10000;

    // Withdrawal fee up to 0.5%
    uint256 public withdrawalFee = 0;
    uint256 public constant withdrawalMax = 10000;

    // Tokens
    address public token;
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // stablecoins
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant susd = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address public constant tusd = 0x0000000000085d4780B73119b644AE5ecd22b376;

    address public btf;

    // User accounts
    address public governance;
    address public controller;
    address public strategist;
    address public timelock;

    // Dex
    address public univ2Router2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // usdc -> btf pair exists?
    bool public swapUsdcForBtf = false;

    constructor(
        address _btf,
        address _token,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public {
        require(_btf != address(0));
        require(_token != address(0));
        require(_governance != address(0));
        require(_strategist != address(0));
        require(_controller != address(0));
        require(_timelock != address(0));

        btf = _btf;
        token = _token;
        governance = _governance;
        strategist = _strategist;
        controller = _controller;
        timelock = _timelock;
    }

    // **** Modifiers **** //

    modifier onlyBenevolent {
        require(
            msg.sender == tx.origin ||
            msg.sender == governance ||
            msg.sender == strategist
        );
        _;
    }

    // **** Views **** //

    function balanceOfWant() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function balanceOfPool() public virtual view returns (uint256);

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    // weth->btf path
    function getSwapPathOfBtf() public view returns (address[] memory){
        address[] memory path;

        if (swapUsdcForBtf) {
            path = new address[](3);
            path[0] = weth;
            path[1] = usdc;
            path[2] = btf;
        } else {
            path = new address[](2);
            path[0] = weth;
            path[1] = btf;
        }
        return path;
    }

    function getName() external virtual pure returns (string memory);

    // **** Setters **** //

    function setBtf(address _btf) public {
        require(msg.sender == governance, "!governance");
        btf = _btf;
    }

    function setDevFundFee(uint256 _devFundFee) external {
        require(msg.sender == timelock, "!timelock");
        devFundFee = _devFundFee;
    }

    function setComFundFee(uint256 _comFundFee) external {
        require(msg.sender == timelock, "!timelock");
        comFundFee = _comFundFee;
    }

    function setBurnFee(uint256 _burnFee) external {
        require(msg.sender == timelock, "!timelock");
        burnFee = _burnFee;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        require(msg.sender == timelock, "!timelock");
        withdrawalFee = _withdrawalFee;
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
        require(msg.sender == timelock, "!timelock");
        controller = _controller;
    }

    function setSwapUsdcForBtf(bool _swapUsdcForBtf) external {
        require(msg.sender == governance, "!governance");
        swapUsdcForBtf = _swapUsdcForBtf;
    }

    // **** State mutations **** //
    function deposit() public virtual;

    // Controller only function for creating additional rewards from dust
    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(token != address(_asset), "token");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    // Contoller only function for withdrawing for free
    // This is used to swap between vaults
    function freeWithdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(token).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        IERC20(token).safeTransfer(msg.sender, _amount);
    }

    // Withdraw partial funds, normally used with a vault withdrawal
    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(token).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        if (withdrawalFee > 0) {
            uint256 _fee = _amount.mul(withdrawalFee).div(withdrawalMax);
            IERC20(token).safeTransfer(IController(controller).comAddr(), _fee);
            _amount = _amount.sub(_fee);
        }

        address _vault = IController(controller).vaults(address(token));
        require(_vault != address(0), "!vault");
        // additional protection so we don't burn the funds

        IERC20(token).safeTransfer(_vault, _amount);
    }

    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();

        balance = IERC20(token).balanceOf(address(this));

        address _vault = IController(controller).vaults(address(token));
        require(_vault != address(0), "!vault");
        // additional protection so we don't burn the funds
        IERC20(token).safeTransfer(_vault, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    function harvest() public virtual;

    // **** Emergency functions ****

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

    function _swapUniswap(
        address[] memory path,
        uint256 _amount
    ) internal {
        // Swap with uniswap
        IERC20(path[0]).safeApprove(univ2Router2, 0);
        IERC20(path[0]).safeApprove(univ2Router2, _amount);

        UniswapRouterV2(univ2Router2).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }

    function _swapUniswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

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

        _swapUniswap(path, _amount);
    }
}
