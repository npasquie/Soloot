//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./SubVault.sol";
import "./LootCoin.sol";

// note pour moi meme : on ne verifiera pas lors des upgrade qu'on ne rend pas la meme carte qu'avec laquelle la personne est arrivee
// pas de reequilibrage du vault faisable non plus :( // todo : quoique ????

contract NFlooT {
    SorareTokens constant private sorareTokens = SorareTokens(0x629A673A8242c2AC4B7B8C5D8735fbeac21A6205);
    SubVault[3] private vault;
    LootCoin private lootCoin;
    
    uint256 constant internal MAX_UINT256 = 2**256 - 1;
    uint256 constant internal ERC20DECIMALSMULTIPLIER = 10 ** 18;
    
    constructor() {
        vault = [new SubVault(0),new SubVault(1),new SubVault(2)]; // 0 -> unique, 1 -> superrare, 2 -> rare
        lootCoin = new LootCoin();
    }
    
    function getLootCoinAddress() public view returns(address) {
        return address(lootCoin);
    }
    
    // needs approval before using
    function quickSell(uint256[] calldata tokenIds) public {
        bool receivedOnlyRareCards = true;
        uint256 tempScarcity;
        uint256 accumulatedScore;
        
        for(uint256 i = 0; i < tokenIds.length; i++){
            ( , ,tempScarcity, , , ) = sorareTokens.getCard(tokenIds[i]);
            if(tempScarcity != 2){
                receivedOnlyRareCards = false;
            }
            sorareTokens.safeTransferFrom(msg.sender, address(vault[tempScarcity]), tokenIds[i]);
            accumulatedScore += (10 ** (2 - tempScarcity)) * ERC20DECIMALSMULTIPLIER;
        }
        lootCoin.mint(msg.sender,receivedOnlyRareCards ? accumulatedScore : getPrice(accumulatedScore)); // todo : recheck poor implementation
    }
    
    function getHoldingsScore() internal view returns(uint256) { // parameter A
        uint256[3] memory vaultBalances = getVaultBalances();
        
        return((
            vaultBalances[0] * 100 +
            vaultBalances[1] * 10 +
            vaultBalances[2]
            ) * ERC20DECIMALSMULTIPLIER);
    }
    
    function getPrice(uint256 score) internal view returns(uint256) {
        // we need to prevent an attack where a card with a massive value can buy the whole vault, then get back his card back
        uint256 nineTenthOfHoldingsScore = (getHoldingsScore()/10)*9;
        
        return(score < nineTenthOfHoldingsScore ? score : nineTenthOfHoldingsScore);
    }
    
    // receives a score based on value provided by the user, and returns the contract-owned tokenId of the card to win
    function getTokenIdByPlaying(uint256 playerScore) internal view returns(uint256) {
        uint256[3] memory vaultBalances = getVaultBalances();
        
        // remember to check that score is sufficient for a try
        
        if(vaultBalances[2] == 0){ // no rare
            
        }
        
        
        // if(vaultBalances[0] == 0){ // no cards in unique vault
        //     if(vaultBalances[1] == 0){ // no cards in super rare vault
        //         require(vaultBalances[2] > 0, "the contract has 0 card"); // no vault has cards
        //         return getRandomTokenIdFromVault(2, vaultBalances); // only rare vault has cards
        //     } else { // no unique, some superrare
        //         if(vaultBalances[2] == 0){ // only superrare vault has cards
        //             return getRandomTokenIdFromVault(1, vaultBalances);
        //         } else { // rare & superrare vaults have cards
        //             return getRandomTokenIdFromVault(pickFromScarcierVault(false, playerScore) ? 1 : 2, vaultBalances);
        //         }
        //     }
        // } else { // some uniques
        //     if(vaultBalances[1] == 0){ // some uniques, no superrare
        //         if(vaultBalances[2] == 0){ // only uniques
        //             return getRandomTokenIdFromVault(0, vaultBalances);
        //         } else { // some uniques and rares
        //             return getRandomTokenIdFromVault(pickFromScarcierVault(true, playerScore) ? 0 : 2, vaultBalances);
        //         }
        //     } else { // some uniques and superrare
        //         if(vaultBalances[2] == 0){ // only uniques and superrare
        //             return getRandomTokenIdFromVault(pickFromScarcierVault(false, playerScore) ? 0 : 1, vaultBalances); // no no no
        //         }
        //     }
        // }
    }
    
    function pickFromScarcierVault(bool vaultsAreTheRareAndUniqueOnes, uint256 playerScore) internal view returns(bool){ // todo : ca va pas j'ai nique cette fonction avec le playerscore
        uint8 valueMultiplier = vaultsAreTheRareAndUniqueOnes ? 100 : 10;
        return getSecondRandomNumber() < MAX_UINT256 * ((playerScore - 1) / (valueMultiplier - 1)); // probability of picking the high vault
    }
    
    function getRandomTokenIdFromVault(uint8 vaultScarcity, uint256[3] memory vaultBalances) internal view returns(uint256){
        return sorareTokens.tokenOfOwnerByIndex(address(vault[vaultScarcity]),getIndexFromRandomUint(vaultBalances[vaultScarcity],getRandomNumber()));
    }
    
    function getRandomNumber() internal view returns(uint256){ // todo : change to use chainlink vrf
        return uint256(blockhash(block.number - 1));
    }
    
    function getSecondRandomNumber() internal view returns(uint256){ // todo : change this awful trick
        return uint256(keccak256(abi.encode(blockhash(block.number - 1))));
    }
    
    function getVaultBalances() internal view returns(uint256[3] memory){
        return [sorareTokens.balanceOf(address(vault[0])),sorareTokens.balanceOf(address(vault[1])),sorareTokens.balanceOf(address(vault[2]))];
    }
    
    function getIndexFromRandomUint(uint256 arrayLength, uint256 randomNumber) internal pure returns(uint256){
        return(randomNumber/(MAX_UINT256/arrayLength));
    }
}