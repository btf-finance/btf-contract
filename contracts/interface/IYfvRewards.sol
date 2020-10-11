pragma solidity ^0.6.2;

interface IYfvRewards {
    function balanceOf(address tokenAddress, address account) external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function weiTotalSupply() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function weiBalanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function stakingPower(address account) external view returns (uint256);

    function vUSDBalance(address account) external view returns (uint256);

    function vETHBalance(address account) external view returns (uint256);

    function claimVETHReward() external;

    function stake(address tokenAddress, uint256 amount, address referrer) external;

    function withdraw(address tokenAddress, uint256 amount) external;

    function exit() external;

    function getReward() external;

    function nextRewardMultiplier() external view returns (uint16);

    function notifyRewardAmount(uint256 reward) external;
}