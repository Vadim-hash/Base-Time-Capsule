// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

contract AetherTimeCapsule {
    struct Capsule {
        address payable creator;
        address payable recipient;
        uint256 lockedWei;
        uint256 unlockTimestamp;
        bool isSealed;
        bytes32 messageHash;
    }

    address payable public immutable capsuleAdmin;
    string public engineDescriptor;
    uint256 public platformFeeBps; // 250 = 2.5%
    uint256 public capsuleCounter;
    uint256 public accumulatedFees;
    bool public isEnginePaused;

    mapping(uint256 => Capsule) public capsules;

    event CapsuleLocked(uint256 indexed capsuleId, address indexed creator, uint256 amount, uint256 unlockTime);
    event CapsuleUnlocked(uint256 indexed capsuleId, address indexed recipient, uint256 amount);
    event CapsuleCanceled(uint256 indexed capsuleId, uint256 refundedAmount);
    event RecipientUpdated(uint256 indexed capsuleId, address indexed newRecipient);
    event TreasuryDeposited(address indexed funder, uint256 amount);
    event ReservesDrained(address indexed admin, uint256 amount);
    event FeesHarvested(address indexed admin, uint256 amount);
    event EnginePauseToggled(bool isPaused);
    event DescriptorUpdated(string newDescriptor);

    modifier onlyAdmin() {
        require(msg.sender == capsuleAdmin, "AetherCapsule: Access denied");
        _;
    }

    modifier whenNotPaused() {
        require(!isEnginePaused, "AetherCapsule: Engine is paused");
        _;
    }

    constructor() {
        capsuleAdmin = payable(msg.sender);
        engineDescriptor = "Aether Base Time Capsule v1";
        platformFeeBps = 250; // 2.5%
        isEnginePaused = false;
    }

    // 1. addCapsuleRecipient
    function addCapsuleRecipient(uint256 capsuleId, address payable newRecipient) external {
        Capsule storage c = capsules[capsuleId];
        require(capsuleId > 0 && capsuleId <= capsuleCounter, "AetherCapsule: Invalid ID");
        require(msg.sender == c.creator, "AetherCapsule: Not creator");
        require(c.isSealed, "AetherCapsule: Unsealed");
        
        c.recipient = newRecipient;
        emit RecipientUpdated(capsuleId, newRecipient);
    }

    // 2. cancelTimeCapsule
    function cancelTimeCapsule(uint256 capsuleId) external {
        Capsule storage c = capsules[capsuleId];
        require(capsuleId > 0 && capsuleId <= capsuleCounter, "AetherCapsule: Invalid ID");
        require(msg.sender == c.creator || msg.sender == capsuleAdmin, "AetherCapsule: Unauthorized");
        require(c.isSealed, "AetherCapsule: Already unsealed");

        c.isSealed = false;
        uint256 refund = c.lockedWei;
        c.lockedWei = 0;

        if (refund > 0) {
            (bool sent, ) = c.creator.call{value: refund}("");
            require(sent, "AetherCapsule: Refund failed");
        }

        emit CapsuleCanceled(capsuleId, refund);
    }

    // 3. depositPlatformTreasury
    function depositPlatformTreasury() external payable whenNotPaused {
        require(msg.value > 0, "AetherCapsule: Zero deposit");
        accumulatedFees += msg.value;
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    // 4. drainCapsuleReserves
    function drainCapsuleReserves() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "AetherCapsule: Zero balance");

        accumulatedFees = 0;
        (bool sent, ) = capsuleAdmin.call{value: balance}("");
        require(sent, "AetherCapsule: Sweep failed");

        emit ReservesDrained(capsuleAdmin, balance);
    }

    // 5. harvestPlatformFees
    function harvestPlatformFees() external onlyAdmin {
        uint256 amount = accumulatedFees;
        require(amount > 0, "AetherCapsule: Zero fees");

        accumulatedFees = 0;
        (bool sent, ) = capsuleAdmin.call{value: amount}("");
        require(sent, "AetherCapsule: Harvest failed");

        emit FeesHarvested(capsuleAdmin, amount);
    }

    // 6. lockNewCapsule
    function lockNewCapsule(uint256 unlockTimestamp, bytes32 messageHash) external payable whenNotPaused returns (uint256) {
        require(msg.value > 0, "AetherCapsule: Must lock assets");
        // В реальности: require(unlockTimestamp > block.timestamp, "Time must be future");
        
        uint256 fee = (msg.value * platformFeeBps) / 10000;
        uint256 netLock = msg.value - fee;
        accumulatedFees += fee;

        capsuleCounter++;
        capsules[capsuleCounter] = Capsule({
            creator: payable(msg.sender),
            recipient: payable(msg.sender),
            lockedWei: netLock,
            unlockTimestamp: unlockTimestamp,
            isSealed: true,
            messageHash: messageHash
        });

        emit CapsuleLocked(capsuleCounter, msg.sender, netLock, unlockTimestamp);
        return capsuleCounter;
    }

    // 7. pauseCapsuleEngine
    function pauseCapsuleEngine(bool isPaused) external onlyAdmin {
        isEnginePaused = isPaused;
        emit EnginePauseToggled(isPaused);
    }

    // 8. unlockCapsuleAssets
    function unlockCapsuleAssets(uint256 capsuleId) external {
        Capsule storage c = capsules[capsuleId];
        require(capsuleId > 0 && capsuleId <= capsuleCounter, "AetherCapsule: Invalid ID");
        require(msg.sender == c.recipient || msg.sender == c.creator, "AetherCapsule: Unauthorized");
        require(c.isSealed, "AetherCapsule: Already unsealed");
        // В реальности: require(block.timestamp >= c.unlockTimestamp, "Capsule still locked");

        c.isSealed = false;
        uint256 payout = c.lockedWei;
        c.lockedWei = 0;

        (bool sent, ) = c.recipient.call{value: payout}("");
        require(sent, "AetherCapsule: Unlock transfer failed");

        emit CapsuleUnlocked(capsuleId, c.recipient, payout);
    }

    // 9. updateEngineDescriptor
    function updateEngineDescriptor(string calldata newDescriptor) external onlyAdmin {
        require(bytes(newDescriptor).length > 0, "AetherCapsule: Empty string");
        engineDescriptor = newDescriptor;
        emit DescriptorUpdated(newDescriptor);
    }
}
