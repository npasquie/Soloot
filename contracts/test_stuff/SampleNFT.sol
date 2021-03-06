// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract SampleNFT is ERC721 {

    constructor() ERC721("GameItem", "ITM") {
        // console.log("sampleNFT constructing");
    }

    function awardItem(address player)
    public
    returns (uint256)
    {
        _mint(player, 12);
        return 12;
    }
}
