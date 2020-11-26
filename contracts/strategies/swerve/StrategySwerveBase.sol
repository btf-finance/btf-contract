pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "../../interface/IController.sol";
import "../../interface/IStrategy.sol";
import "../../interface/Gauge.sol";
import "../../interface/ISwerveFi.sol";
import "../../interface/UniswapRouterV2.sol";
import "../../interface/USDT.sol";

abstract contract StrategySwerveBase {
    enum TokenIndex {DAI, USDC, USDT, TUSD}

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Fees 5% in total
    // - 1.5%   devFundFee for development fund
    // - 2%     comFundFee for community fund
    // - 1.5%   used to burn/repurchase btfs
    uint256 public devFundFee = 150;
    uint256 public constant devFundMax = 10000;

    uint256 public comFundFee = 200;
    uint256 public constant comFundMax = 10000;

    uint256 public burnFee = 150;
    uint256 public constant burnMax = 10000;

    // Withdrawal fee 0.5%
    uint256 public withdrawalFee = 0;
    uint256 public constant withdrawalMax = 10000;

    // settable arbitrage tolerance, 1%
    uint256 public arbTolerance = 100;
    uint256 public constant arbToleranceMax = 10000;

    uint[4] public mixTokenUnit = [10 ** 18, 10 ** 6, 10 ** 6, 10 ** 18];

    // the matching enum record used to determine the index
    TokenIndex tokenIndex;

    // price checkpoint preventing attacks
    uint256 public wantPriceCheckpoint;

    // gauge of swerve
    address public constant gauge = 0xb4d0C929cD3A1FbDc6d57E7D3315cF0C4d6B4bFa;

    // swusd
    address public constant mixToken = 0x77C6E4a580c0dCE4E5c7a17d0bc077188a83A059;

    // tokens we're farming
    address public constant swrv = 0xB8BAa0e4287890a5F79863aB62b7F175ceCbD433;

    // swusdv2 pool
    address public constant swerve = 0xa746c67eB7915Fa832a4C2076D403D4B68085431;

    // swerve minter
    address constant public mintr = 0x2c988c3974AD7E604E276AE0294a7228DEf67974;

    // stablecoins
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant tusd = 0x0000000000085d4780B73119b644AE5ecd22b376;
    address[4] public stablecoins = [dai, usdc, usdt, tusd];

    // weth
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // dex
    address public constant univ2Router2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // dai/usdc
    address public want;
    // the matching enum record used to determine the index
    TokenIndex wantTokenIndex;

    address public btf;

    address public governance;
    address public controller;
    address public strategist;
    address public timelock;

    constructor(
        address _btf,
        uint256 _tokenIndex,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public {
        btf = _btf;
        tokenIndex = TokenIndex(_tokenIndex);
        want = stablecoins[_tokenIndex];
        governance = _governance;
        strategist = _strategist;
        controller = _controller;
        timelock = _timelock;

        // starting with a stable price, the mainnet will override this value
        wantPriceCheckpoint = mixTokenUnit[_tokenIndex];
    }

    // **** Views ****

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public view returns (uint256) {
        uint256 gaugeBalance = Gauge(gauge).balanceOf(address(this));
        if (gaugeBalance == 0) {
            // this if-statement is necessary to avoid transaction reverts
            return 0;
        }
        return wantValueFromMixToken(gaugeBalance);
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function getName() external virtual pure returns (string memory);

    function getHarvestable() external returns (uint256) {
        return Gauge(gauge).claimable_tokens(address(this));
    }

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

    // **** State Mutations ****

    /**
    * Uses the Swerve protocol to convert the want asset into to mixed token.
    */
    function mixFromWant() internal {
        uint256 wantBalance = IERC20(want).balanceOf(address(this));
        if (wantBalance > 0) {
            IERC20(want).safeApprove(swerve, 0);
            IERC20(want).safeApprove(swerve, wantBalance);
            // we can accept 0 as minimum because this is called only by a trusted role
            uint256 minimum = 0;
            uint256[4] memory coinAmounts = wrapCoinAmount(wantBalance);
            ISwerveFi(swerve).add_liquidity(
                coinAmounts, minimum
            );
        }
        // now we have the mixed token
    }

    /**
    * Uses the Swerve protocol to convert the mixed token back into the want asset. If it cannot
    * acquire the limit amount, it will acquire the maximum it can.
    */
    function mixToWant(uint256 wantLimit) internal {
        uint256 mixTokenBalance = IERC20(mixToken).balanceOf(address(this));

        // this is the maximum number of want we can get for our mixed token
        uint256 wantMaximumAmount = wantValueFromMixToken(mixTokenBalance);
        if (wantMaximumAmount == 0) {
            return;
        }

        if (wantLimit < wantMaximumAmount) {
            // we want less than what we can get, we ask for the exact amount
            // now we can remove the liquidity
            uint256[4] memory tokenAmounts = wrapCoinAmount(wantLimit);
            IERC20(mixToken).safeApprove(swerve, 0);
            IERC20(mixToken).safeApprove(swerve, mixTokenBalance);
            ISwerveFi(swerve).remove_liquidity_imbalance(
                tokenAmounts, mixTokenBalance
            );
        } else {
            // we want more than we can get, so we withdraw everything
            IERC20(mixToken).safeApprove(swerve, 0);
            IERC20(mixToken).safeApprove(swerve, mixTokenBalance);
            ISwerveFi(swerve).remove_liquidity_one_coin(mixTokenBalance, int128(tokenIndex), 0);
        }
        // now we have want asset
    }

    function wantValueFromMixToken(uint256 mixTokenBalance) public view returns (uint256) {
        return ISwerveFi(swerve).calc_withdraw_one_coin(mixTokenBalance,
            int128(tokenIndex));
    }

    /**
    * Wraps the coin amount in the array for interacting with the Curve protocol
    */
    function wrapCoinAmount(uint256 amount) internal view returns (uint256[4] memory) {
        uint256[4] memory amounts = [uint256(0), uint256(0), uint256(0), uint256(0)];
        amounts[uint56(tokenIndex)] = amount;
        return amounts;
    }

    function investAllUnderlying() internal {
        // convert the entire balance not yet invested into mixToken first
        mixFromWant();

        // then deposit into the mixToken vault
        uint256 mixTokenBalance = IERC20(mixToken).balanceOf(address(this));
        if (mixTokenBalance > 0) {
            IERC20(mixToken).safeApprove(gauge, 0);
            IERC20(mixToken).safeApprove(gauge, mixTokenBalance);
            Gauge(gauge).deposit(mixTokenBalance);
        }
    }

    function depositArbCheck() public view returns (bool) {
        uint256 currentPrice = wantValueFromMixToken(1e18);
        if (currentPrice < wantPriceCheckpoint) {
            return currentPrice.mul(arbToleranceMax).div(wantPriceCheckpoint) > arbToleranceMax - arbTolerance;
        } else {
            return currentPrice.mul(arbToleranceMax).div(wantPriceCheckpoint) < arbToleranceMax + arbTolerance;
        }
    }

    function deposit() public {
        require(depositArbCheck(), "Too much arb");
        investAllUnderlying();
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

        // invest back the rest
        investAllUnderlying();
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

        // invest back the rest
        investAllUnderlying();
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
        // withdraw all from gauge
        Gauge(gauge).withdraw(Gauge(gauge).balanceOf(address(this)));
        // convert the mix to want, we want the entire balance
        mixToWant(uint256(~0));
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        uint256 beforeBalance = IERC20(want).balanceOf(address(this));
        // withdraw all from gauge
        Gauge(gauge).withdraw(Gauge(gauge).balanceOf(address(this)));
        // convert the mix to want, but get at most amountWant
        mixToWant(_amount);
        uint256 afterBalance = IERC20(want).balanceOf(address(this));

        return Math.min(_amount, afterBalance.sub(beforeBalance));
    }

    function harvest() public {
        // Collects SWRV tokens
        Mintr(mintr).mint(gauge);
        uint256 _swrv = IERC20(swrv).balanceOf(address(this));
        if (_swrv > 0) {
            _swapUniswap(swrv, want, _swrv);
        }

        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            if (devFundFee > 0) {
                uint256 _devFundFee = _want.mul(devFundFee).div(devFundMax);
                if (want == usdt) {
                    USDT(want).transfer(IController(controller).devAddr(), _devFundFee);
                } else {
                    IERC20(want).transfer(IController(controller).devAddr(), _devFundFee);
                }
                _want = _want.sub(_devFundFee);
            }

            // Burn some btfs first
            if (burnFee > 0) {
                uint256 _burnFee = _want.mul(burnFee).div(burnMax);
                _swapUniswap(want, btf, _burnFee);
                IERC20(btf).transfer(
                    IController(controller).burnAddr(),
                    IERC20(btf).balanceOf(address(this))
                );
                _want = _want.sub(_burnFee);
            }

            if (comFundFee > 0) {
                uint256 _comFundFee = _want.mul(comFundFee).div(comFundMax);
                if (want == usdt) {
                    USDT(want).transfer(IController(controller).comAddr(), _comFundFee);
                } else {
                    IERC20(want).transfer(IController(controller).comAddr(), _comFundFee);
                }
            }

            investAllUnderlying();
        }

        wantPriceCheckpoint = wantValueFromMixToken(1e18);
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
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

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

