// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/layerzero-v2/packages/layerzero-v2/evm/messagelib/contracts/uln/interfaces/ILayerZeroDVN.sol";
import "../lib/layerzero-v2/packages/layerzero-v2/evm/protocol/contracts/interfaces/ILayerZeroEndpointV2.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/layerzero-v2/packages/layerzero-v2/evm/messagelib/contracts/uln/interfaces/IReceiveUlnE2.sol";

contract LayerZeroDVNContract is Ownable, ILayerZeroDVN {
    mapping(bytes32 => bool) public verifiedPackets;

    ILayerZeroEndpointV2 public immutable endpoint;

    // The DVN contract will know about the sendMessageLib address.
    address public sendMessageLib;
    address public receiveMessageLib;

    constructor(ILayerZeroEndpointV2 _endpoint, address _receiveMessageLib, address _sendMessageLib) Ownable(msg.sender) {
        endpoint = _endpoint;
        sendMessageLib = _sendMessageLib;
        receiveMessageLib = _receiveMessageLib;
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
        return 0;
    }

    /// @notice Returns the fee required for a given message verification job.
    function getFee(uint32 _dstEid, uint64 _confirmations, address _sender, bytes calldata _options)
    external
    view
    override
    returns (uint256 fee)
    {
        return 0;
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