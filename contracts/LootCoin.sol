//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// todo : remove
import "hardhat/console.sol";

// should we made this coin flashable - permitable - safewrapped ?

// interface INFlooT {
//     function buyLootBoxFromLootCoinContract(address from) external payable;
// }

// In NFlooT's ecosystem, this contract can only be owned by the NFlooT contract, devs can't create coins
// for themselves in a different way than other users
contract LootCoin is ERC20, Ownable {
    uint256 constant private ERC20_DECIMALS_MULTIPLIER = 10 ** 18;
    
    constructor() ERC20("LootCoin", "LOOT") {}
    
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function buyALootBox() public payable{
        _burn(msg.sender, 2 * ERC20_DECIMALS_MULTIPLIER);
        console.log(msg.value);
        (bool success, ) = owner().call{value: msg.value}(abi.encodeWithSignature("buyLootBoxFromLootCoinContract(address)",msg.sender));
        require(success, "call to NFlooT failed");
    }
}
