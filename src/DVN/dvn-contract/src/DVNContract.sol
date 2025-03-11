// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/layerzero-v2/packages/layerzero-v2/evm/messagelib/contracts/uln/interfaces/ILayerZeroDVN.sol";
import "../lib/layerzero-v2/packages/layerzero-v2/evm/protocol/contracts/interfaces/ILayerZeroEndpointV2.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/layerzero-v2/packages/layerzero-v2/evm/messagelib/contracts/uln/interfaces/IReceiveUlnE2.sol";

contract LayerZeroDVNContract is Ownable, ILayerZeroDVN {
    mapping(uint32 => uint256) public messageFees;
    mapping(bytes32 => bool) public verifiedPackets;

    event MessageFeeSet(uint32 indexed dstEid, uint256 messageFee);
    ILayerZeroEndpointV2 public immutable endpoint;

    // The DVN contract will know about the sendMessageLib address.
    address public sendMessageLib;
    address public receiveMessageLib;

    constructor(ILayerZeroEndpointV2 _endpoint, address _receiveMessageLib, address _sendMessageLib, uint32[] memory _dstEids, uint256[] memory _fees) Ownable(msg.sender) {
        endpoint = _endpoint;
        sendMessageLib = _sendMessageLib;
        receiveMessageLib = _receiveMessageLib;
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
        require(msg.sender == sendMessageLib, "Caller must be the sendMessageLib");

        uint32 dstEid = _param.dstEid;
        uint256 requiredFee = messageFees[dstEid];
        require(msg.value >= requiredFee, "Insufficient fee");
        fee = requiredFee;
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
        return fee;
    }

    function verifyPacket(
        bytes calldata _packetHeader,
        bytes32 _payloadHash,
        uint64 _confirmations
    ) external onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(_packetHeader, _payloadHash));
        require(!verifiedPackets[key], "Packet already verified");
        IReceiveUlnE2(receiveMessageLib).verify(_packetHeader, _payloadHash, _confirmations);
        verifiedPackets[key] = true;
    }
    function verified(
        bytes calldata _packetHeader,
        bytes32 _payloadHash
    ) external view returns (bool) {
        bytes32 key = keccak256(abi.encodePacked(_packetHeader, _payloadHash));
        return verifiedPackets[key];
    }
}