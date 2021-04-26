//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
//import "hardhat/console.sol";

abstract contract SorareTokens {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external virtual;
    function balanceOf(address owner) public view virtual returns(uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256);
    function getCard(uint256 tokenId) public view virtual returns (
        uint256 playerId,
        uint16 season,
        uint256 scarcity,
        uint16 serialNumber,
        bytes memory metadata,
        uint16 clubId);
}

contract SubVault is IERC721Receiver {
    SorareTokens private sorareTokens = SorareTokens(0x629A673A8242c2AC4B7B8C5D8735fbeac21A6205);
    uint8 private nbOfNFTReceived;
    uint256 private allowedScarcity;
    
    constructor(uint256 _allowedScarcity){
        allowedScarcity = _allowedScarcity;
    }
    
    function getNbOfNFTReceived() public view returns(uint8){
        return nbOfNFTReceived;
    }

    function onERC721Received(address, address, uint256 tokenId, bytes memory) public virtual override returns (bytes4) {
        sorareTokens.ownerOf(tokenId); // will revert if the NFT doesn't come from SorareTokens
        ( , ,uint256 controlledScarcity, , , ) = sorareTokens.getCard(tokenId);
        require(controlledScarcity == allowedScarcity, "this vault does not accept this card scarcity");
        nbOfNFTReceived++;
        return 0x150b7a02; // signals ERC-721 onERC721Received compliance
    }
}
