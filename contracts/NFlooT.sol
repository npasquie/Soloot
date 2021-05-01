//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./SubVault.sol";
import "./LootCoin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";

// todo : remove assertions after checks
// todo : note requirements UI implications

// note pour moi meme : on ne verifiera pas lors des upgrade qu'on ne rend pas la meme carte qu'avec laquelle la personne est arrivee

contract NFlooT is Ownable, VRFConsumerBase {
    // those constants are for ethereum mainnet
    SorareTokens constant private SORARE_TOKENS = SorareTokens(0x629A673A8242c2AC4B7B8C5D8735fbeac21A6205);
    bytes32 constant private CHAINLINK_KEY_HASH = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    
    uint256 private chainlinkVrfFee = 2 * ERC20_DECIMALS_MULTIPLIER;
    
    uint256 constant private MAX_UINT256 = type(uint256).max;
    uint256 constant private ERC20_DECIMALS_MULTIPLIER = 10 ** 18;
    
    SubVault[3] private vault;
    LootCoin private lootCoin;
    
    uint256[3] private potentialVaultBalanceDrawNegativeImpact;
    mapping(bytes32 => address) private userAwaitingDraw;
    mapping(bytes32 => uint256[3]) private vrfRequestAssociatedProbabilities;
    
    constructor(address _vrfCoordinator, address _link) 
        VRFConsumerBase(_vrfCoordinator, _link) {
            vault = [new SubVault(0),new SubVault(1),new SubVault(2)]; // 0 -> unique, 1 -> superrare, 2 -> rare
            lootCoin = new LootCoin();
        }
    
    function getLootCoinAddress() public view returns(address) {
        return address(lootCoin);
    }
    
    function setChainlinkVrfFee(uint256 fee) public onlyOwner {
        chainlinkVrfFee = fee;
    }
    
    // core features
    
    // needs approval before using
    function quickSell(uint256[] calldata tokenIds) public { // gives lootcoins against cards
        uint256 tempScarcity;
        uint256 accumulatedScore;
        
        for(uint256 i = 0; i < tokenIds.length; i++){
            ( , ,tempScarcity, , , ) = SORARE_TOKENS.getCard(tokenIds[i]);
            SORARE_TOKENS.safeTransferFrom(msg.sender, address(vault[tempScarcity]), tokenIds[i]);
            accumulatedScore += getScarcityScore(tempScarcity);
        }
        lootCoin.mint(msg.sender,accumulatedScore * ERC20_DECIMALS_MULTIPLIER); // todo : add dev tax
    }
    
    function buyLootBox() public { // draws a card againt 2 lootcoins
        require(getDrawableVaultBalance(2) > 0, "no rare card available for a draw");
        
        drawOfValue2();
    }
    
    function drawOfValue2() private { // picks up the draw process for lootbox or upgrade of value 2
        if(getDrawableVaultBalance(1) > 0){
            if(getDrawableVaultBalance(0) > 0){
                drawFromAllVaultsWithLowScore(2 * ERC20_DECIMALS_MULTIPLIER);
            } else { // no unique card available
                drawFromTwoVaults(2,1,2 * ERC20_DECIMALS_MULTIPLIER);
            }
        } else { // no super rare card available
            if(getDrawableVaultBalance(0) > 0){
                drawFromTwoVaults(2,0,2 * ERC20_DECIMALS_MULTIPLIER);
            } else { // only rare available
                drawFromOneVault(2);
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
            sendRandomCardToAddressFromVault(2,userAwaitingDraw[requestId],randomness);
            return;
        } else if (randomNumber < vrfRequestAssociatedProbabilities[requestId][2] + vrfRequestAssociatedProbabilities[requestId][1]) {
            sendRandomCardToAddressFromVault(1,userAwaitingDraw[requestId],randomness);
            return;
        } else {
            sendRandomCardToAddressFromVault(0,userAwaitingDraw[requestId],randomness);
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
        uint256 higherScarcityDrawProbabilty = ((score - getScarcityScore(lowerScarcity)) * ERC20_DECIMALS_MULTIPLIER) / ((getScarcityScore(higherScarcity) - getScarcityScore(lowerScarcity)) * ERC20_DECIMALS_MULTIPLIER);
        
        potentialVaultBalanceDrawNegativeImpact[lowerScarcity]++;
        potentialVaultBalanceDrawNegativeImpact[higherScarcity]++;
        userAwaitingDraw[requestId] = msg.sender;
        
        vrfRequestAssociatedProbabilities[requestId][higherScarcity] = higherScarcityDrawProbabilty;
        vrfRequestAssociatedProbabilities[requestId][lowerScarcity] = ERC20_DECIMALS_MULTIPLIER - higherScarcityDrawProbabilty;
    }

    function drawFromAllVaultsWithLowScore(uint256 score) private{
        assert(score == 2 * ERC20_DECIMALS_MULTIPLIER || score == 11 * ERC20_DECIMALS_MULTIPLIER);
        
        bytes32 requestId = requestRandomness(CHAINLINK_KEY_HASH, chainlinkVrfFee,0);
        uint256 scoreMinusOne = score - (1 * ERC20_DECIMALS_MULTIPLIER);
        
        potentialVaultBalanceDrawNegativeImpact[0]++;
        potentialVaultBalanceDrawNegativeImpact[1]++;
        potentialVaultBalanceDrawNegativeImpact[2]++;
        userAwaitingDraw[requestId] = msg.sender;
        vrfRequestAssociatedProbabilities[requestId] = [
        ERC20_DECIMALS_MULTIPLIER, // evaluated last, no need to calculate
            (10 * scoreMinusOne) / 189,
            ((200 * ERC20_DECIMALS_MULTIPLIER) - (11 * score)) / 189
            ];
    }

    
    // internal lib 
    
    function sendRandomCardToAddressFromVault(uint8 scarcity, address recipient, uint256 randomness) private {
        SORARE_TOKENS.safeTransferFrom(address(vault[scarcity]),recipient,getIndexFromRandomUint(SORARE_TOKENS.balanceOf(address(vault[scarcity])),uint256(keccak256(abi.encode(randomness)))));
    }
    
    function getScarcityScore(uint256 scarcity) private pure returns(uint256){
        return (10 ** (2 - scarcity));
    }
    
    function getDrawableVaultBalance(uint8 scarcity) private view returns(uint256){
        return SORARE_TOKENS.balanceOf(address(vault[scarcity])) - potentialVaultBalanceDrawNegativeImpact[scarcity];
    }
    
    function getIndexFromRandomUint(uint256 arrayLength, uint256 randomNumber) private pure returns(uint256){
        return(randomNumber/(MAX_UINT256/arrayLength)); // todo : check edge cases
    }
}
