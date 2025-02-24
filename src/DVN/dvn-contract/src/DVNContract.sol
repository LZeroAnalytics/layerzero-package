// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../lib/layerzero-v2/packages/layerzero-v2/evm/messagelib/contracts/uln/interfaces/ILayerZeroDVN.sol";
import "../lib/layerzero-v2/packages/layerzero-v2/evm/protocol/contracts/interfaces/ILayerZeroEndpointV2.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";


contract LayerZeroDVNContract is Ownable, ILayerZeroDVN {
    // Set a fixed fee for demonstration. Adjust as needed.
    uint256 public feePerJob = 0.001 ether;

    mapping(bytes32 => uint256) public assignedJobs;

    event JobAssigned(address indexed dvn, bytes32 indexed key, uint256 fee);

    ILayerZeroEndpointV2 public immutable endpoint;

    constructor(
        ILayerZeroEndpointV2 _endpoint
    ) Ownable(msg.sender) {
        endpoint = _endpoint;
    }


    /// @notice Called by the endpoint when a DVN is assigned to verify a packet.
    function assignJob(AssignJobParam calldata _param, bytes calldata _options)
    external
    payable
    override
    returns (uint256 fee)
    {
        require(msg.value >= feePerJob, "Insufficient fee");
        fee = feePerJob;

        // Generate a key from the packet header and payload hash
        bytes32 key = keccak256(abi.encodePacked(_param.packetHeader, _param.payloadHash));
        assignedJobs[key] = fee;

        emit JobAssigned(msg.sender, key, fee);
        return fee;
    }

    /// @notice Returns the fee required for a given message verification job.
    function getFee(uint32 _dstEid, uint64 _confirmations, address _sender, bytes calldata _options)
    external
    view
    override
    returns (uint256 fee)
    {
        // For simplicity, always return feePerJob.
        fee = feePerJob;
        return fee;
    }
}
