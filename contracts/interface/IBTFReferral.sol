pragma solidity ^0.6.2;

interface IBTFReferral {
    function setReferrer(address farmer, address referrer) external;
    function getReferrer(address farmer) external view returns (address);
}
