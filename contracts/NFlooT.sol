//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./SubVault.sol";
import "./LootCoin.sol";

// todo : remove assertions after checks
// todo : note requirements UI implications

// note pour moi meme : on ne verifiera pas lors des upgrade qu'on ne rend pas la meme carte qu'avec laquelle la personne est arrivee

contract NFlooT {
    SorareTokens constant private SORARE_TOKENS = SorareTokens(0x629A673A8242c2AC4B7B8C5D8735fbeac21A6205);
    bytes32 constant private CHAINLINK_KEY_HASH = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445; // mainnet
    
    uint256 constant private MAX_UINT256 = type(uint256).max;  // 2**256 - 1
    uint256 constant private ERC20DECIMALSMULTIPLIER = 10 ** 18;
    
    SubVault[3] private vault;
    LootCoin private lootCoin;
    
    uint256[3] private potentialVaultBalanceDrawNegativeImpact;
    mapping(address => bytes32) private vrfRequestId;
    mapping(bytes32 => uint256[3]) private vrfRequestAssociatedProbabilities;
    
    constructor() {
        vault = [new SubVault(0),new SubVault(1),new SubVault(2)]; // 0 -> unique, 1 -> superrare, 2 -> rare
        lootCoin = new LootCoin();
    }
    
    function getLootCoinAddress() public view returns(address) {
        return address(lootCoin);
    }
    
    // core features
    
    // needs approval before using
    function quickSell(uint256[] calldata tokenIds) public { // gives lootcoins against cards
        uint256 tempScarcity;
        uint256 accumulatedScore;
        
        for(uint256 i = 0; i < tokenIds.length; i++){
            ( , ,tempScarcity, , , ) = SORARE_TOKENS.getCard(tokenIds[i]);
            SORARE_TOKENS.safeTransferFrom(msg.sender, address(vault[tempScarcity]), tokenIds[i]);
            accumulatedScore += (10 ** (2 - tempScarcity)) * ERC20DECIMALSMULTIPLIER;
        }
        lootCoin.mint(msg.sender,accumulatedScore); // todo : add dev tax
    }
    
    function buyLootBox() public { // draws a card againt 2 lootcoins
        require(SORARE_TOKENS.balanceOf(address(vault[2])) != 0, "at least one rare card must be in vault");
        
        value_2_draw();
    }
    
    function value_2_draw() private { // picks up the draw process for lootbox or upgrade of value 2
        if(SORARE_TOKENS.balanceOf(address(vault[1])) != 0){
            if(SORARE_TOKENS.balanceOf(address(vault[0])) != 0){
                //  blue star func
            } else { // no unique card available
                
            }
        } else { // no super rare card available
            
        }
    }

    function drawFromAllVaultsWithLowScore(uint256 score) private{
        assert(score == 2 * MAX_UINT256 || score == 11 * MAX_UINT256);
        
        require(vrfRequestId[msg.sender] == 0, "this address is already waiting for a draw");
        
        vrfRequestId[msg.sender] = 
    }

    
    // internal lib 

    function getRandomNumber() private view returns(uint256){ // todo : change to use chainlink vrf
        return uint256(blockhash(block.number - 1));
    }
    
    function getSecondRandomNumber() private view returns(uint256){ // todo : change this awful trick
        return uint256(keccak256(abi.encode(blockhash(block.number - 1))));
    }
    
    function getIndexFromRandomUint(uint256 arrayLength, uint256 randomNumber) private pure returns(uint256){
        return(randomNumber/(MAX_UINT256/arrayLength));
    }
}
