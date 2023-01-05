pragma solidity >=0.7.0 <0.9.0;
contract Timer {
    uint public startTime;

    constructor() public {
        startTime = block.timestamp;
    }

    function getElapsedTime() public view returns (uint) {
        return block.timestamp-startTime;
    }
}