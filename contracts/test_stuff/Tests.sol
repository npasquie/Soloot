//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "hardhat/console.sol";

abstract contract UniswapV2Router02 {
    function WETH() external virtual pure returns (address);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external virtual payable returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external virtual returns (uint[] memory amounts);
}

abstract contract WETH9 { // https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code
    function deposit() public virtual payable;
    function approve(address guy, uint wad) public virtual returns (bool);
    mapping (address => uint) public balanceOf;
}

interface ISwapRouter { // uniswap V3
    function exactOutputSingle(ISwapRouter.ExactOutputSingleParams calldata params) external returns (uint256 amountIn);
    
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }
}

interface IERC20 {
    function balanceOf(address account) external returns (uint256);
}

contract WrapLOL{
    uint256 public lolvalue;
    
    function deposit() public payable{
        lolvalue += msg.value;
    }
}

contract Tests {
    uint256 constant private ERC20_DECIMALS_MULTIPLIER = 10 ** 18;
    address constant private WETHaddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant private uniV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant private LINKaddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    UniswapV2Router02 constant private UNISWAP_ROUTER = UniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    constructor(){
        WETH9(WETHaddress).approve(uniV3Router,type(uint256).max);
    }
    
    function lolTest() public payable{
        WrapLOL lol = new WrapLOL();
        console.log(msg.value);
        lol.deposit{value: msg.value}();
        console.log(lol.lolvalue());
    }
    
    receive() external payable{}
    
    function uniswapTest() public payable{
        console.log("uniswapTest");
        address[] memory path = new address[](2);
        path[0] = UNISWAP_ROUTER.WETH();
        path[1] = LINKaddress; // LINK
        
        UNISWAP_ROUTER.swapETHForExactTokens{value: msg.value}(2 * ERC20_DECIMALS_MULTIPLIER, path, address(this), block.timestamp);
        console.log(IERC20(path[1]).balanceOf(address(this)));
    }
    
    function uniswapV3Test() public payable{
        console.log("v3 test");
        WETH9(WETHaddress).deposit{value: msg.value}();
        ISwapRouter(uniV3Router).exactOutputSingle(ISwapRouter.ExactOutputSingleParams({
            tokenIn: WETHaddress,
            tokenOut: LINKaddress,
            fee: 3000, // 0.3% fee
            recipient: address(this),
            deadline: block.timestamp,
            amountOut: ERC20_DECIMALS_MULTIPLIER * 2,
            amountInMaximum: msg.value,
            sqrtPriceLimitX96: 0
        }));
        console.log((IERC20(LINKaddress)).balanceOf(address(this)));
    }
}
