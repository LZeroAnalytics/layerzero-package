// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/layerzero-v2/packages/layerzero-v2/evm/messagelib/contracts/uln/interfaces/ILayerZeroDVN.sol";
import "../lib/layerzero-v2/packages/layerzero-v2/evm/protocol/contracts/interfaces/ILayerZeroEndpointV2.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/layerzero-v2/packages/layerzero-v2/evm/messagelib/contracts/uln/interfaces/IReceiveUlnE2.sol";

contract LayerZeroDVNContract is Ownable, ILayerZeroDVN {
    mapping(bytes32 => uint256) public assignedJobs;
    mapping(uint32 => uint256) public messageFees;

    event JobAssigned(address indexed dvn, bytes32 indexed key, uint256 fee);
    event MessageFeeSet(uint32 indexed dstEid, uint256 messageFee);
    ILayerZeroEndpointV2 public immutable endpoint;

    // The DVN contract will know about the Receive library address.
    address public receiveLib;

    constructor(ILayerZeroEndpointV2 _endpoint, address _receiveLib, uint32[] memory _dstEids, uint256[] memory _fees) Ownable(msg.sender) {
        endpoint = _endpoint;
        receiveLib = _receiveLib;
        require(_dstEids.length == _fees.length, "LayerZeroDVNContract: Length mismatch");
        for (uint256 i = 0; i < _dstEids.length; i++) {
            messageFees[_dstEids[i]] = _fees[i];
            emit MessageFeeSet(_dstEids[i], _fees[i]);
        }
    }

    /// @notice Called by the endpoint when a DVN is assigned to verify a packet.
    function assignJob(AssignJobParam calldata _param, bytes calldata _options)
    external
    payable
    override
    returns (uint256 fee)
    {
        // Restrict assignJob so that only the endpoint can call it.
        require(msg.sender == address(endpoint), "Caller must be endpoint");

        uint32 dstEid = abi.decode(_options, (uint32));
        uint256 requiredFee = messageFees[dstEid];
        require(requiredFee > 0, "LayerZeroDVNContract: invalid destination");
        require(msg.value >= requiredFee, "Insufficient fee");
        fee = requiredFee;
        bytes32 key = keccak256(abi.encodePacked(_param.packetHeader, _param.payloadHash));
        assignedJobs[key] = fee;
        emit JobAssigned(msg.sender, key, fee);
        return fee;
    }

    function setMessageFee(uint32 dstEid, uint256 fee) external onlyOwner {
        messageFees[dstEid] = fee;
        emit MessageFeeSet(dstEid, fee);
    }

    /// @notice Returns the fee required for a given message verification job.
    function getFee(uint32 _dstEid, uint64 _confirmations, address _sender, bytes calldata _options)
    external
    view
    override
    returns (uint256 fee)
    {
        fee = messageFees[_dstEid];
        require(fee > 0, "LayerZeroDVNContract: invalid destination");
        return fee;
    }

    function verifyPacket(
        bytes calldata _packetHeader,
        bytes32 _payloadHash,
        uint64 _confirmations
    ) external onlyOwner {
        IReceiveUlnE2(receiveLib).verify(_packetHeader, _payloadHash, _confirmations);
    }
}