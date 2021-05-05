//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "hardhat/console.sol";

abstract contract UniswapV2Router02 {
    function WETH() external virtual pure returns (address);
    // function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external virtual payable returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external virtual returns (uint[] memory amounts);
}

abstract contract WETH9 { // https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code
//    function deposit() public virtual payable; // called via address.call{}
    function approve(address guy, uint wad) public virtual returns (bool);
    mapping (address => uint)                       public  balanceOf;
}

contract Tests {
    UniswapV2Router02 constant private UNISWAP_ROUTER = UniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    
    function uniswapTest() public payable{
        //uint256 amount = msg.value;
        
        (bool success, ) = UNISWAP_ROUTER.WETH().call{value: msg.value}(abi.encodeWithSignature("deposit()"));
        require(success, "deposit in weth failed");
        
        console.log(WETH9(UNISWAP_ROUTER.WETH()).balanceOf(address(this)));
    }
}
