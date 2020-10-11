pragma solidity 0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./BTFToken.sol";
import "./interface/IMigratorChef.sol";
import "./interface/IBTFReferral.sol";

// MasterChef is the master of BTF
contract MasterChef is Ownable {
    uint256 public constant DURATION = 7 days;

    uint256 public TotalSupply = 1000000 * 1e18;
    uint256 public initReward = 100000 * 1e18;
    uint256 public periodFinish = 0;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public rewardRate = 0;

    address public rewardReferral;
    uint256 public constant referralMax = 10000;
    // 1%
    uint256 public referralPercent = 100;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardPerTokenPaid;
        uint256 rewards;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    // The BTF TOKEN!
    BTFToken public btf;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BTF mining starts.
    uint256 public startBlock;
    // add the same LP token only once
    mapping(address => bool) lpExists;

    event RewardAdded(uint256 reward);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(BTFToken _btf, uint256 _startBlock) public {
        btf = _btf;
        startBlock = _startBlock;
    }

    function setRewardReferral(address _rewardReferral) external onlyOwner {
        rewardReferral = _rewardReferral;
    }

    function setReferralPercent(uint256 _referralPercent) external onlyOwner {
        require(_referralPercent > 0 && _referralPercent < 100, "_referralPercent is wrong");
        referralPercent = _referralPercent;
    }

    modifier reduceHalve() {
        require(btf.totalSupply() <= TotalSupply, "Out of limited.");

        if (periodFinish == 0) {
            periodFinish = block.timestamp.add(DURATION);
            rewardRate = initReward.div(DURATION);
            btf.mint(address(this), initReward);
        } else if (block.timestamp >= periodFinish) {
            initReward = initReward.sub(initReward.mul(10).div(100));
            rewardRate = initReward.div(DURATION);
            btf.mint(address(this), initReward);
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(initReward);
        }
        _;
    }

    modifier checkStart(){
        require(block.number > startBlock, "not start");
        _;
    }

    modifier updateReward(uint256 _pid, address _user) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        pool.rewardPerTokenStored = rewardPerToken(_pid);
        pool.lastUpdateTime = lastTimeRewardApplicable();
        if (_user != address(0)) {
            user.rewards = earned(_pid, _user);
            user.rewardPerTokenPaid = pool.rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return (periodFinish == 0 || block.timestamp < periodFinish) ? block.timestamp : periodFinish;
    }

    function rewardPerToken(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            return pool.rewardPerTokenStored;
        }
        return pool.rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(pool.lastUpdateTime == 0 ? block.timestamp : pool.lastUpdateTime)
            .mul(rewardRate)
            .mul(pool.allocPoint)
            .div(totalAllocPoint)
            .mul(1e18)
            .div(lpSupply)
        );
    }

    function earned(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        return user.amount
        .mul(rewardPerToken(_pid).sub(user.rewardPerTokenPaid))
        .div(1e18)
        .add(user.rewards);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken) public onlyOwner {
        require(!lpExists[address(_lpToken)], "do not add the same lp token more than once");

        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastUpdateTime : 0,
            rewardPerTokenStored : 0
            }));

        lpExists[address(_lpToken)] = true;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Update the given pool's BTF allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint) public onlyOwner {
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // View function to see pending BTFs on frontend.
    function pendingBTF(uint256 _pid, address _user) external view returns (uint256) {
        return earned(_pid, _user);
    }

    function _getReward(uint256 _pid, address _user) private {
        UserInfo storage user = userInfo[_pid][_user];
        uint256 reward = earned(_pid, _user);
        if (reward > 0) {
            user.rewards = 0;

            uint256 btfBal = btf.balanceOf(address(this));
            if (reward > btfBal) {
                reward = btfBal;
            }

            uint256 referrerReward = 0;
            address referrer = address(0);
            if (rewardReferral != address(0)) {
                referrer = IBTFReferral(rewardReferral).getReferrer(_user);
            }
            if (referrer != address(0)) {
                referrerReward = reward.mul(referralPercent).div(referralMax);
                btf.transfer(referrer, referrerReward);
                emit RewardPaid(referrer, referrerReward);
            }

            btf.transfer(_user, reward.sub(referrerReward));
            emit RewardPaid(_user, reward.sub(referrerReward));
        }
    }

    // Deposit LP tokens to MasterChef for BTF allocation.
    function deposit(uint256 _pid, uint256 _amount, address referrer) public updateReward(_pid, msg.sender) reduceHalve checkStart {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        _getReward(_pid, msg.sender);
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        emit Deposit(msg.sender, _pid, _amount);

        if (rewardReferral != address(0) && referrer != address(0)) {
            IBTFReferral(rewardReferral).setReferrer(msg.sender, referrer);
        }
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public updateReward(_pid, msg.sender) reduceHalve checkStart {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        _getReward(_pid, msg.sender);
        user.amount = user.amount.sub(_amount);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens & Rewards from MasterChef
    function exit(uint256 _pid) external {
        withdraw(_pid, balanceOf(msg.sender));
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewards = 0;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

}