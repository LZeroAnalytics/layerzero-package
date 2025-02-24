// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/layerzero-v2/packages/layerzero-v2/evm/messagelib/contracts/uln/interfaces/ILayerZeroDVN.sol";
import "../lib/layerzero-v2/packages/layerzero-v2/evm/protocol/contracts/interfaces/ILayerZeroEndpointV2.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/layerzero-v2/packages/layerzero-v2/evm/messagelib/contracts/uln/interfaces/IReceiveUlnE2.sol";

contract LayerZeroDVNContract is Ownable, ILayerZeroDVN {
    uint256 public feePerJob = 0.001 ether;
    mapping(bytes32 => uint256) public assignedJobs;
    event JobAssigned(address indexed dvn, bytes32 indexed key, uint256 fee);
    ILayerZeroEndpointV2 public immutable endpoint;

    // The DVN contract will know about the Receive library address.
    address public receiveLib;

    constructor(ILayerZeroEndpointV2 _endpoint, address _receiveLib) Ownable(msg.sender) {
        endpoint = _endpoint;
        receiveLib = _receiveLib;
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
        fee = feePerJob;
        return fee;
    }

    /// @notice Public function for verifying a packet.
    /// This function calls the receive library's verify function.
    /// When this function is called by the offchain DVN component, msg.sender is the DVN contract.
    function verifyPacket(
        bytes calldata _packetHeader,
        bytes32 _payloadHash,
        uint64 _confirmations
    ) external onlyOwner {
        // Now the DVN contract calls the verify function on the receive library.
        IReceiveUlnE2(receiveLib).verify(_packetHeader, _payloadHash, _confirmations);
    }
}