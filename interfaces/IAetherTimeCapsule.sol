// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

interface IAetherTimeCapsule {
    function lockNewCapsule(uint256 unlockTimestamp, bytes32 messageHash) external payable returns (uint256);
    function unlockCapsuleAssets(uint256 capsuleId) external;
}
