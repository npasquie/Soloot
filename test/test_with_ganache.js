const myWeb3 = require("web3");
const hre = require("hardhat")
const assert = require('assert');

const constants = require("../constants")
const sorareABI = require("./sorareABI.json")

const nftReceiverJson = require("../artifacts/contracts/NFTReceiver.sol/NFTReceiver.json")
const sampleNFTJson = require("../artifacts/contracts/SampleNFT.sol/SampleNFT.json")
const subVaultJson = require("../artifacts/contracts/SubVault.sol/SubVault.json")
const nflootJson = require("../artifacts/contracts/NFlooT.sol/NFlooT.json")
const lootCoinJson = require("../artifacts/contracts/LootCoin.sol/LootCoin.json")

const uniqueManuelCardId = '109885007871154280541989865417424574301301402155804365246179380903455247947907' // unique
const superrareLanzini = '31035610442611312751521785752696909636386712321495552227249729640827270478289' // super rare
const rareGonzallo = '75980177082139641009950466359570436445475229369489312117963960992921578840022' // rare

const linkTokenAddress = '0x514910771AF9Ca656af840dff83E8264EcF986CA'
const vrfCoordinatorAddress = '0xf0d54349aDdcf704F77AE15b96510dEA15cb7952'

const addressFullOfTokens = "0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8"

const oneETHinWeis = '1000000000000000000'

const delay = ms => new Promise(res => setTimeout(res, ms));

describe("sorare test suite", function (){
    this.timeout(5000)

    let myweb3
    let accounts
    let sorareTokens
    let nftReceiver
    let subVault
    let nfloot
    let lootCoin

    before(async function (){
        hre.run("node")
        await delay(3000)
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: ["0xe50D690c68fBA9d6724e860D2980b7e05C50250f"]}
        )
        myweb3 = new myWeb3("http://localhost:8545")
        accounts = await myweb3.eth.getAccounts()
        sorareTokens = await new myweb3.eth.Contract(sorareABI,constants.sorareTokensAddress)
    })

    it("should transfer a sorare card to another account", async function (){
        await sendOneEthTo(constants.manuelCardHolderAddress, myweb3)
        await sendContrFunc(sorareTokens.methods.safeTransferFrom(constants.manuelCardHolderAddress,constants.acc0,uniqueManuelCardId), constants.manuelCardHolderAddress)
        let newOwner = await sorareTokens.methods.ownerOf(uniqueManuelCardId).call()
        assert.equal(newOwner,constants.acc0)
    })

    it("should transfer the card from an user to the receiver contract", async function (){
        nftReceiver = await deployContract(nftReceiverJson, constants.acc0, myweb3)
        let contrAddress = nftReceiver.options.address
        await sendContrFunc(sorareTokens.methods.safeTransferFrom(constants.acc0,contrAddress,uniqueManuelCardId), constants.acc0)
        let nbOfReceivedNFTs = await nftReceiver.methods.getNbOfNFTReceived().call()
        assert.equal(nbOfReceivedNFTs, 1)
    })

    // it("should refuse an NFT that doesn't come from sorare", async function (){
    //     let sampleNFT = await deployContract(sampleNFTJson, constants.acc0, myweb3)
    //     subVault = await deployContract(subVaultJson, constants.acc0, myweb3, [0])
    //     await sendContrFunc(sampleNFT.methods.awardItem(subVault.options.address), constants.acc0)
    //     let nbOfReceivedNFTs = await subVault.methods.getNbOfNFTReceived().call()
    //     assert.equal(nbOfReceivedNFTs, 0)
    // })

    // it("should accept a sorare card send from a contract", async function (){
    //     await sendContrFunc(nftReceiver.methods.sendPossessedNFT(
    //         constants.sorareTokensAddress,
    //         uniqueManuelCardId,
    //         subVault.options.address), constants.acc0)
    //     let nbOfReceivedNFTs = await subVault.methods.getNbOfNFTReceived().call()
    //     assert.equal(nbOfReceivedNFTs, 1)
    // })

    it("should refuse a sorare card with wrong scarcity", async function (){
        let owner = await impersonateCardOwner(rareGonzallo, sorareTokens, myweb3)
        await assert.rejects(async ()=>{await sendContrFunc(sorareTokens.methods.safeTransferFrom(owner,subVault.options.address,rareGonzallo),owner)})
    })

    it("should give 9.5 coins for a super rare card", async function (){
        nfloot = await deployContract(nflootJson,constants.acc0, myweb3,[linkTokenAddress,vrfCoordinatorAddress])
        let owner = await impersonateCardOwner(superrareLanzini, sorareTokens, myweb3)
        await sendContrFunc(sorareTokens.methods.setApprovalForAll(nfloot.options.address, true),owner)
        await sendContrFunc(nfloot.methods.quickSell([superrareLanzini]),owner)
        let lootCoinAddress = await nfloot.methods.getLootCoinAddress().call()
        lootCoin = await new myweb3.eth.Contract(lootCoinJson.abi, lootCoinAddress)
        let lootCoinBalance = await lootCoin.methods.balanceOf(owner).call()
        assert.equal(lootCoinBalance,10000000000000000000 * 95/100)
    })

    it("should fail to mint lootcoins from another address than NFloot contract", async function (){
        await assert.rejects(async ()=>{await sendContrFunc(lootCoin.methods.mint(constants.acc0, oneETHinWeis + '0'),constants.acc0)})
    })
})

// personnal library
async function sendContrFunc(stuffToDo, from){
    let gas = await stuffToDo.estimateGas({from: from})
    return await stuffToDo.send({from: from, gas: gas + 21000, gasPrice: '30000000'})
}

async function deployContract(json, from, web3, args){
    let contract = await new web3.eth.Contract(json.abi)
    return await sendContrFunc(contract.deploy({data:json.bytecode, arguments: args}), from)
}

async function impersonateCardOwner(cardID, sorareTokens, web3){
    let owner = await sorareTokens.methods.ownerOf(cardID).call()
    await sendOneEthTo(owner, web3)
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [owner]})
    return owner
}

async function sendOneEthTo(recipient, web3) {
    await web3.eth.sendTransaction({
        from: constants.acc0,
        to: recipient,
        value: oneETHinWeis}) // sends 1 ETH
}
