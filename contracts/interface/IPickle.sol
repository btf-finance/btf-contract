// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

interface IPickle {
    function withdrawAll() external;
    function depositAll() external;
    function getRatio() external view returns (uint256);
    function withdraw(uint256) external;
    function balanceOf(address) external view returns (uint256);
}