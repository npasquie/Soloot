//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

abstract contract SorareTokens {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract SubVault is IERC721Receiver {
    SorareTokens private sorareTokens = SorareTokens(0x629A673A8242c2AC4B7B8C5D8735fbeac21A6205);
    uint8 private nbOfNFTReceived;
    
    function getNbOfNFTReceived() public view returns(uint8){
        return nbOfNFTReceived;
    }

    function onERC721Received(address, address, uint256 tokenId, bytes memory) public virtual override returns (bytes4) {
        sorareTokens.ownerOf(tokenId); // will revert if the NFT doesn't come from SorareTokens
        nbOfNFTReceived++;
        return 0x150b7a02; // signals ERC-721 onERC721Received compliance
    }
}
