// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ProofAxis
 * @dev Minimal on-chain proof-of-existence and provenance registry for hashed artifacts
 * @notice Stores timestamped hashes with optional subject and context labels
 */
contract ProofAxis {
    address public owner;

    struct Proof {
        address submitter;    // who registered the proof
        bytes32 dataHash;     // hash of the off-chain data/document
        string  subject;      // short label for what this proof refers to
        string  context;      // optional context (e.g., case id, project id)
        uint256 createdAt;    // block timestamp of registration
        bool    isActive;     // soft delete flag
    }

    // Sequential id for proofs
    uint256 public totalProofs;

    // proofId => Proof
    mapping(uint256 => Proof) public proofs;

    // dataHash => proofId (first registration wins)
    mapping(bytes32 => uint256) public hashToProofId;

    // submitter => proofIds[]
    mapping(address => uint256[]) public proofsOf;

    event ProofRegistered(
        uint256 indexed proofId,
        address indexed submitter,
        bytes32 indexed dataHash,
        string subject,
        string context,
        uint256 timestamp
    );

    event ProofDeactivated(
        uint256 indexed proofId,
        address indexed caller,
        uint256 timestamp
    );

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier proofExists(uint256 proofId) {
        require(proofs[proofId].submitter != address(0), "Proof not found");
        _;
    }

    modifier onlySubmitter(uint256 proofId) {
        require(proofs[proofId].submitter == msg.sender, "Not submitter");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Register a new proof-of-existence for a hash
     * @param dataHash Hash of the off-chain data (e.g., keccak256 of file)
     * @param subject Short human-readable subject
     * @param context Optional context string
     * @return proofId Newly created proof identifier
     */
    function registerProof(
        bytes32 dataHash,
        string calldata subject,
        string calldata context
    ) external returns (uint256 proofId) {
        require(dataHash != bytes32(0), "Invalid hash");
        require(hashToProofId[dataHash] == 0 && (totalProofs == 0 || proofs[0].dataHash != dataHash), "Hash already registered");

        proofId = totalProofs;
        totalProofs += 1;

        proofs[proofId] = Proof({
            submitter: msg.sender,
            dataHash: dataHash,
            subject: subject,
            context: context,
            createdAt: block.timestamp,
            isActive: true
        });

        // store mapping for fast lookup by hash
        hashToProofId[dataHash] = proofId;

        proofsOf[msg.sender].push(proofId);

        emit ProofRegistered(
            proofId,
            msg.sender,
            dataHash,
            subject,
            context,
            block.timestamp
        );
    }

    /**
     * @dev Deactivate an existing proof (soft delete)
     * @param proofId Identifier of the proof
     */
    function deactivateProof(uint256 proofId)
        external
        proofExists(proofId)
        onlySubmitter(proofId)
    {
        Proof storage p = proofs[proofId];
        require(p.isActive, "Already inactive");

        p.isActive = false;

        emit ProofDeactivated(proofId, msg.sender, block.timestamp);
    }

    /**
     * @dev Check if a given hash has a registered active proof
     * @param dataHash Hash to check
     * @return exists True if a proof exists
     * @return active True if proof is active
     * @return proofId The associated proof ID (0 if none and no collision with id 0 hash)
     */
    function verifyHash(bytes32 dataHash)
        external
        view
        returns (bool exists, bool active, uint256 proofId)
    {
        proofId = hashToProofId[dataHash];

        if (totalProofs == 0) {
            return (false, false, 0);
        }

        // Special handling: if first proof has id 0 and same hash, mapping will be 0
        if (proofId == 0 && proofs[0].dataHash != dataHash) {
            return (false, false, 0);
        }

        Proof memory p = proofs[proofId];
        exists = (p.submitter != address(0) && p.dataHash == dataHash);
        active = p.isActive;
    }

    /**
     * @dev Get all proof IDs submitted by a given address
     * @param user Address to query
     */
    function getProofsOf(address user) external view returns (uint256[] memory) {
        return proofsOf[user];
    }

    /**
     * @dev Transfer contract ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }
}
