//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";


contract NFTReceiver is IERC721Receiver {
    uint8 nbOfNFTReceived;
    
    function getNbOfNFTRecived() public view returns (uint8) {
        return nbOfNFTReceived;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        console.log('erc721 recu');
        nbOfNFTReceived = nbOfNFTReceived + 1;
        return 0x150b7a02; // signals ERC-721 onERC721Received compliance
    }
}
