//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./SubVault.sol";
import "./LootCoin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";

// todo : remove assertions after checks
// todo : note requirements UI implications

// note pour moi meme : on ne verifiera pas lors des upgrade qu'on ne rend pas la meme carte qu'avec laquelle la personne est arrivee

abstract contract UniswapV2Router02 {
    function WETH() external virtual pure returns (address);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external virtual payable returns (uint[] memory amounts);
}

contract NFlooT is Ownable, VRFConsumerBase {
    // those constants are for ethereum mainnet
    SorareTokens constant private SORARE_TOKENS = SorareTokens(0x629A673A8242c2AC4B7B8C5D8735fbeac21A6205);
    UniswapV2Router02 constant private UNISWAP_ROUTER = UniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    bytes32 constant private CHAINLINK_KEY_HASH = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    uint8 constant private RARE = 2;
    uint8 constant private SUPER_RARE = 1;
    uint8 constant private UNIQUE = 0;
    
    uint256 constant private MAX_UINT256 = type(uint256).max;
    uint256 constant private ERC20_DECIMALS_MULTIPLIER = 10 ** 18;
    
    uint256 public devFee = 34154638541460313000000000000000000; // about 10$
    uint256 public pendingDevLootCoins;
    uint256 private chainlinkVrfFee = 2 * ERC20_DECIMALS_MULTIPLIER;
    address private immutable linkAddress;
    
    SubVault[3] private vault;
    LootCoin private lootCoin;
    
    uint256[3] private potentialVaultBalanceDrawNegativeImpact;
    mapping(bytes32 => address) private userAwaitingDraw;
    mapping(bytes32 => uint256[3]) private vrfRequestAssociatedProbabilities;
    
    constructor(address _vrfCoordinator, address _link) 
        VRFConsumerBase(_vrfCoordinator, _link) {
            vault = [new SubVault(UNIQUE),new SubVault(SUPER_RARE),new SubVault(RARE)]; // 0 -> unique, 1 -> superrare, 2 -> rare
            lootCoin = new LootCoin();
            linkAddress = _link;
        }
    
    function getLootCoinAddress() public view returns(address) {
        return address(lootCoin);
    }
    
    function setChainlinkVrfFee(uint256 fee) public onlyOwner {
        chainlinkVrfFee = fee;
    }
    
    function setDevFee(uint256 fee) public onlyOwner {
        devFee = fee;
    }
    
    function harvestDevLootCoins() public {
        lootCoin.mint(owner(), pendingDevLootCoins);
        pendingDevLootCoins = 0;
    }
    
    // core features
    
    // needs approval before using
    function quickSell(uint256[] calldata tokenIds) public { // gives lootcoins against cards
        uint256 tempScarcity;
        uint256 accumulatedScore;
        
        for(uint256 i = 0; i < tokenIds.length; i++){
            ( , ,tempScarcity, , , ) = SORARE_TOKENS.getCard(tokenIds[i]);
            SORARE_TOKENS.safeTransferFrom(msg.sender, address(vault[tempScarcity]), tokenIds[i]);
            accumulatedScore += scarcityScore(tempScarcity);
        }
        lootCoin.mint(msg.sender,accumulatedScore * ERC20_DECIMALS_MULTIPLIER * 95/100);
        pendingDevLootCoins += accumulatedScore * ERC20_DECIMALS_MULTIPLIER * 5/100;
    }
    
    function buyLootBox() public payable { // draws a card againt 2 lootcoins
        require(drawableVaultBalance(RARE) > 0, "no rare card available for a draw");
        buyLinkFee();
        lootCoin.burn(msg.sender, 2 * ERC20_DECIMALS_MULTIPLIER);
        
        drawOfValue2();
    }
    
    function upgrade(uint256[2] calldata tokenIds) public payable { // draws one card against 2 (with fair odds)
        uint256 score = scarcityScore(cardScarcity(tokenIds[0])) + scarcityScore(cardScarcity(tokenIds[1]));
        SORARE_TOKENS.safeTransferFrom(msg.sender, address(vault[cardScarcity(tokenIds[0])]), tokenIds[0]); // todo check revert on non normal scarcity
        SORARE_TOKENS.safeTransferFrom(msg.sender, address(vault[cardScarcity(tokenIds[1])]), tokenIds[1]);
        buyLinkFee();
        payable(owner()).transfer(devFee);
        if (score > 100){
            drawFromOneVault(UNIQUE);
        } else if (score == 2){
            drawOfValue2();
        } else {
            if(drawableVaultBalance(UNIQUE) > 0){
                if (score == 11) {
                    drawFromAllVaultsWithLowScore(score * ERC20_DECIMALS_MULTIPLIER);
                } else {
                    if (drawableVaultBalance(RARE) > 0){
                        drawFromAllVaultScoreIs20();
                    } else {
                        drawFromTwoVaults(SUPER_RARE,UNIQUE,score);
                    }
                }
            } else {
                drawFromOneVault(SUPER_RARE);
            }
        }
    }
    
    // funcs
    
    function buyLinkFee() private {
        address[] memory path = new address[](2);
        path[0] = UNISWAP_ROUTER.WETH();
        path[1] = linkAddress;
        UNISWAP_ROUTER.swapETHForExactTokens(chainlinkVrfFee, path, address(this), block.timestamp);
    }
    
    function drawOfValue2() private { // picks up the draw process for lootbox or upgrade of value 2
        if(drawableVaultBalance(SUPER_RARE) > 0){
            if(drawableVaultBalance(UNIQUE) > 0){
                drawFromAllVaultsWithLowScore(2 * ERC20_DECIMALS_MULTIPLIER);
            } else { // no unique card available
                drawFromTwoVaults(RARE,SUPER_RARE,2);
            }
        } else { // no super rare card available
            if(drawableVaultBalance(UNIQUE) > 0){
                drawFromTwoVaults(RARE,UNIQUE,2);
            } else { // only rare available
                drawFromOneVault(RARE);
            }
        }
    }
    
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 randomNumber = randomness % ERC20_DECIMALS_MULTIPLIER;
        for(uint256 i = 0; i < 3; i++){
            if(vrfRequestAssociatedProbabilities[requestId][i] > 0){
                potentialVaultBalanceDrawNegativeImpact[i]--;
            }
        }
        if(randomNumber < vrfRequestAssociatedProbabilities[requestId][2]){
            sendRandomCardToAddressFromVault(RARE,userAwaitingDraw[requestId],randomness);
            return;
        } else if (randomNumber < vrfRequestAssociatedProbabilities[requestId][2] + vrfRequestAssociatedProbabilities[requestId][1]) {
            sendRandomCardToAddressFromVault(SUPER_RARE,userAwaitingDraw[requestId],randomness);
            return;
        } else {
            sendRandomCardToAddressFromVault(UNIQUE,userAwaitingDraw[requestId],randomness);
        }
    }
    
    function drawFromOneVault(uint8 scarcity) private {
        bytes32 requestId = requestRandomness(CHAINLINK_KEY_HASH, chainlinkVrfFee,0);
        potentialVaultBalanceDrawNegativeImpact[scarcity]++;
        userAwaitingDraw[requestId] = msg.sender;
        vrfRequestAssociatedProbabilities[requestId][scarcity] = ERC20_DECIMALS_MULTIPLIER;
    }
    
    function drawFromTwoVaults(uint8 lowerScarcity, uint8 higherScarcity, uint256 score) private{
        bytes32 requestId = requestRandomness(CHAINLINK_KEY_HASH, chainlinkVrfFee,0);
        uint256 higherScarcityDrawProbabilty = ((score - scarcityScore(lowerScarcity)) * ERC20_DECIMALS_MULTIPLIER) / ((scarcityScore(higherScarcity) - scarcityScore(lowerScarcity)) * ERC20_DECIMALS_MULTIPLIER);
        
        potentialVaultBalanceDrawNegativeImpact[lowerScarcity]++;
        potentialVaultBalanceDrawNegativeImpact[higherScarcity]++;
        userAwaitingDraw[requestId] = msg.sender;
        
        vrfRequestAssociatedProbabilities[requestId][higherScarcity] = higherScarcityDrawProbabilty;
        vrfRequestAssociatedProbabilities[requestId][lowerScarcity] = ERC20_DECIMALS_MULTIPLIER - higherScarcityDrawProbabilty;
    }
    
    function drawFromAllVaultsWithLowScore(uint256 score) private {
        assert(score == 2 * ERC20_DECIMALS_MULTIPLIER || score == 11 * ERC20_DECIMALS_MULTIPLIER);
        
        bytes32 requestId = requestRandomness(CHAINLINK_KEY_HASH, chainlinkVrfFee,0);
        uint256 scoreMinusOne = score - (1 * ERC20_DECIMALS_MULTIPLIER);
        
        potentialVaultBalanceDrawNegativeImpact[RARE]++;
        potentialVaultBalanceDrawNegativeImpact[SUPER_RARE]++;
        potentialVaultBalanceDrawNegativeImpact[UNIQUE]++;
        userAwaitingDraw[requestId] = msg.sender;
        vrfRequestAssociatedProbabilities[requestId] = [
        ERC20_DECIMALS_MULTIPLIER, // evaluated last, no need to calculate
            (10 * scoreMinusOne) / 189,
            ((200 * ERC20_DECIMALS_MULTIPLIER) - (11 * score)) / 189
            ];
    }
    
    function drawFromAllVaultScoreIs20() private {
        bytes32 requestId = requestRandomness(CHAINLINK_KEY_HASH, chainlinkVrfFee,0);
        
        potentialVaultBalanceDrawNegativeImpact[RARE]++;
        potentialVaultBalanceDrawNegativeImpact[SUPER_RARE]++;
        potentialVaultBalanceDrawNegativeImpact[UNIQUE]++;
        userAwaitingDraw[requestId] = msg.sender;
        vrfRequestAssociatedProbabilities[requestId] = [
            ERC20_DECIMALS_MULTIPLIER,
            (800 * ERC20_DECIMALS_MULTIPLIER / 999),
            (80 * ERC20_DECIMALS_MULTIPLIER / 999)
            ];
    }
    
    // private lib 
    
    function cardScarcity(uint256 tokenId) private view returns(uint256){ // doesn't checks if card exists
        ( , ,uint256 scarcity, , , ) = SORARE_TOKENS.getCard(tokenId);
        return scarcity;
    }
    
    function sendRandomCardToAddressFromVault(uint8 scarcity, address recipient, uint256 randomness) private {
        SORARE_TOKENS.safeTransferFrom(address(vault[scarcity]),recipient,getIndexFromRandomUint(SORARE_TOKENS.balanceOf(address(vault[scarcity])),uint256(keccak256(abi.encode(randomness)))));
    }
    
    function scarcityScore(uint256 scarcity) private pure returns(uint256){
        return (10 ** (2 - scarcity));
    }
    
    function drawableVaultBalance(uint8 scarcity) private view returns(uint256){
        return SORARE_TOKENS.balanceOf(address(vault[scarcity])) - potentialVaultBalanceDrawNegativeImpact[scarcity];
    }
    
    function getIndexFromRandomUint(uint256 arrayLength, uint256 randomNumber) private pure returns(uint256){
        return(randomNumber/(MAX_UINT256/arrayLength)); // todo : check edge cases
    }
}
