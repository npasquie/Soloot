//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";


contract NFTReceiver is IERC721Receiver {
    uint8 private nbOfNFTReceived;
    
    function getNbOfNFTReceived() public view returns(uint8){
        return nbOfNFTReceived;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        nbOfNFTReceived++;
        return 0x150b7a02; // signals ERC-721 onERC721Received compliance
    }
}
