//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

// todo : remove
import "hardhat/console.sol";

interface INFLoot {
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external;
} 

contract MockVRFCoordinator {
    uint256 public requestNonce;
    mapping(uint256 => Request) request;
    uint256 constant private ERC20_DECIMALS_MULTIPLIER = 10 ** 18;
    
    struct Request {
        address sender;
        bytes32 ID;
    }
    
    function onTokenTransfer(address _sender, uint _value, bytes memory _data) external{
        require(msg.sender == 0x514910771AF9Ca656af840dff83E8264EcF986CA, "not called by LINK token");
        require(_value >= 2 * ERC20_DECIMALS_MULTIPLIER, "not enough paid for vrf");
        (bytes32 keyHash, uint256 seed) = abi.decode(_data, (bytes32, uint256));
        request[requestNonce] = Request(_sender,makeRequestId(keyHash, makeVRFInputSeed(keyHash, seed, _sender, requestNonce)));
        console.log("computed requestId: %s", uint256(makeRequestId(keyHash, makeVRFInputSeed(keyHash, seed, _sender, requestNonce))));
        requestNonce++;
    }
    
    function resolveRequest(uint256 nonce, uint256 randomness) public {
        INFLoot nfloot = INFLoot(request[nonce].sender);
        nfloot.rawFulfillRandomness(request[nonce].ID, randomness);
    }
    
    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
  
    function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,address _requester, uint256 _nonce) internal pure returns (uint256){
        return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }
}
