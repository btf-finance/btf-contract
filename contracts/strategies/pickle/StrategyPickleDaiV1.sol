// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../StrategyBase.sol";
import "../../interface/IPickle.sol";
import "../../interface/IPickleMasterChef.sol";

contract StrategyPickleDaiV1 is StrategyBase {
    // pickle
    address public pickleJar = address(0x6949Bb624E8e8A90F87cD2058139fcd77D2F3F87);
    address public pickleMasterChef = address(0xbD17B1ce622d73bD438b9E658acA5996dc394b0d);

    // want pickle tokens
    address public pickeToken = address(0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5); 
    address public want = address(0x6B175474E89094C44Da98b954EedeAC495271d0F); // dai
    
    uint256 public poolId = 16;

    constructor(
        address _btf,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public
    StrategyBase(_btf, want, _governance, _strategist, _controller, _timelock)
    {
    }

    // **** Views ****
    function getName() external override pure returns (string memory) {
        return "StrategyPickleDaiV1";
    }

    function balanceOfPool() public override view returns (uint256) {
        uint256 wantBal = IPickle(pickleJar).balanceOf(address(this));
        uint256 pickleRatio = IPickle(pickleJar).getRatio();
        uint256 pickleShares = getPickleMasterChefBalance();
        return wantBal.add(pickleRatio).mul(pickleShares).div(1e18);
    }

    function getHarvestable() external returns (uint256) {
        return IPickleMasterChef(pickleMasterChef).pendingPickle(poolId, address(this));
    }

    function setPoolId(uint256 _poolId) public {
        require(msg.sender == governance, "!governance");
        poolId = _poolId;
    }

    // **** State Mutation functions ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.
        // quitPickleMasterChef();
        // only claim rewards
        IPickleMasterChef(pickleMasterChef).withdraw(poolId, 0);
        claimAndInvest();
    }

    function deposit() public override {
        uint256 investBal = IERC20(want).balanceOf(address(this));
        if (investBal > 0) {
            IERC20(want).safeApprove(pickleJar, 0);
            IERC20(want).safeApprove(pickleJar, investBal);
            IPickle(pickleJar).depositAll();
        }

        uint256 pickleJarBal = IERC20(pickleJar).balanceOf(address(this));
        if (pickleJarBal > 0) {
            IERC20(pickleJar).safeApprove(pickleMasterChef, 0);
            IERC20(pickleJar).safeApprove(pickleMasterChef, pickleJarBal);
            IPickleMasterChef(pickleMasterChef).deposit(poolId, pickleJarBal);
        }
    }

    function _withdrawSome(uint256 amount) internal override returns (uint256) {
        uint256 investPerPickleShare = IPickle(pickleJar).getRatio();
        uint256 _amount = amount.mul(1e18).div(investPerPickleShare);
        (uint256 bal,) = IPickleMasterChef(pickleMasterChef).userInfo(poolId, address(this));
        if (_amount > bal) {
            _amount = bal;
        }

        uint256 before = IERC20(pickleJar).balanceOf(address(this));

        IPickleMasterChef(pickleMasterChef).withdraw(poolId, _amount);
        uint256 _after = IERC20(pickleJar).balanceOf(address(this));
        _amount = _after.sub(before);

        // unstake pjar
        before = IERC20(want).balanceOf(address(this));

        IPickle(pickleJar).withdraw(_amount);
        _after = IERC20(want).balanceOf(address(this));

        require(_after >= before, "withdraw error from pJar!");
        _amount = _after.sub(before);
        return _amount;
    }

    /**
     * Withdraws dai from the investment pool that mints crops.
     */
    function withdrawFromPickle(uint256 amount) internal {
        quitPickleMasterChef();
        // we need to calculate the pickle shares
        uint256 investPerPickleShare = IPickle(pickleJar).getRatio();
        uint256 sharesToWithdraw = amount.mul(1e18).div(investPerPickleShare);
        IERC20(pickleJar).safeApprove(pickleJar, 0);
        IERC20(pickleJar).safeApprove(pickleJar, sharesToWithdraw);
        IPickle(pickleJar).withdraw(sharesToWithdraw);
    }

    function quitPickleMasterChef() internal {
        uint256 bal = getPickleMasterChefBalance();
        if (bal > 0) {
            IPickleMasterChef(pickleMasterChef).withdraw(poolId, bal);
        }
    }

    function getPickleMasterChefBalance() internal view returns (uint256 bal) {
        (bal,) = IPickleMasterChef(pickleMasterChef).userInfo(poolId, address(this));
        return bal;
    }

    function claimAndInvest() internal {
        uint256 pickleBalance = IERC20(pickeToken).balanceOf(address(this));
        if (pickleBalance > 0) {
            _swapUniswap(pickeToken, weth, pickleBalance);

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
                _swapUniswap(weth, want, _weth);
            }

            uint256 _want = IERC20(want).balanceOf(address(this));
            if (_want > 0) {
                deposit();
            }
        }
    }
}
