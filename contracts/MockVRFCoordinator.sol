//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

interface INFLoot {
    function fulfillRandomness(bytes32 requestId, uint256 randomness) external;
} 

contract MockVRFCoordinator {
    uint256 public requestNonce;
    mapping(uint256 => Request) request;
    
    struct Request {
        address sender;
        bytes32 ID;
    }
    
    function onTokenTransfer(address _sender, uint _value, bytes memory _data) external{
        (bytes32 keyHash, uint256 seed) = abi.decode(_data, (bytes32, uint256));
        request[requestNonce] = Request(_sender,makeRequestId(keyHash, makeVRFInputSeed(keyHash, seed, _sender, requestNonce)));
        requestNonce++;
    }
    
    function resolveRequest(uint256 nonce) public {
        INFLoot nfloot = INFLoot(request[nonce].sender);
        nfloot.fulfillRandomness(request[nonce].ID, uint256(keccak256(abi.encode(block.number))));
    }
    
    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
  
    function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,address _requester, uint256 _nonce) internal pure returns (uint256){
        return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }
}
