// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract SampleNFT is ERC721 {

    constructor() ERC721("GameItem", "ITM") {
        console.log("constructor");
    }

    function awardItem(address player)
    public
    returns (uint256)
    {
        console.log("award item, address received : " , player);
        _mint(player, 12);
        return 12;
    }

    function myOwnerOf(uint256 tokenId) public view virtual returns (address){
        console.log("ownerof - arg received : " , tokenId);
        return ownerOf(tokenId);
    }
}
