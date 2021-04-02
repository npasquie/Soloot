//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";


contract NFTReceiver is IERC721Receiver {

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        console.log('erc721 recu');
        return this.onERC721Received.selector;
    }
}
