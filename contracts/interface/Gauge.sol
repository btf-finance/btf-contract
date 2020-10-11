pragma solidity ^0.6.2;

interface Gauge {
    function deposit(uint) external;

    function balanceOf(address) external view returns (uint);

    function withdraw(uint) external;

    function user_checkpoint(address) external;

    function claimable_tokens(address) external returns (uint256);
}

interface VotingEscrow {
    function create_lock(uint256 v, uint256 time) external;

    function increase_amount(uint256 _value) external;

    function increase_unlock_time(uint256 _unlock_time) external;

    function withdraw() external;
}

interface Mintr {
    function mint(address) external;
}