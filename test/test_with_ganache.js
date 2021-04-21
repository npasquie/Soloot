const myWeb3 = require("web3");
const constants = require("../constants")
const sorareABI = require("./sorareABI.json")
const nftReceiverJson = require("../artifacts/contracts/NFTReceiver.sol/NFTReceiver.json")
const sampleNFTJson = require("../artifacts/contracts/SampleNFT.sol/SampleNFT.json")
const subVaultJson = require("../artifacts/contracts/SubVault.sol/SubVault.json")
const assert = require('assert');
const uniqueManuelCardId = '109885007871154280541989865417424574301301402155804365246179380903455247947907'

describe("sorare test suite", function (){
    this.timeout(10000)

    let myweb3
    let accounts
    let sorareTokens

    before(async function (){
        myweb3 = new myWeb3("http://localhost:8545")
        accounts = await myweb3.eth.getAccounts()
        sorareTokens = await new myweb3.eth.Contract(sorareABI,constants.sorareTokensAddress)
    })

    it("should transfer a sorare card to another account", async function (){
        await myweb3.eth.sendTransaction({
            from: constants.acc0,
            to: constants.manuelCardHolderAddress,
            value: '1000000000000000000'}) // sends 1 ETH
        await sendContrFunc(sorareTokens.methods.safeTransferFrom(constants.manuelCardHolderAddress,constants.acc0,uniqueManuelCardId), constants.manuelCardHolderAddress)
        let newOwner = await sorareTokens.methods.ownerOf(uniqueManuelCardId).call()
        assert.equal(newOwner,constants.acc0)
    })

    it("should transfer the card from an user to the receiver contract", async function (){
        let nftReceiver = await deployContract(nftReceiverJson, constants.acc0, myweb3)
        let contrAddress = nftReceiver.options.address
        await sendContrFunc(sorareTokens.methods.safeTransferFrom(constants.acc0,contrAddress,uniqueManuelCardId), constants.acc0)
        let nbOfReceivedNFTs = await nftReceiver.methods.getNbOfNFTReceived().call()
        assert.equal(nbOfReceivedNFTs, 1)
    })

    it("should refuse an NFT that doesn't come from sorare", async function (){
        let sampleNFT = await deployContract(sampleNFTJson, constants.acc0, myweb3)
        let subVault = await deployContract(subVaultJson, constants.acc0, myweb3)
        await sendContrFunc(sampleNFT.methods.awardItem(subVault.options.address), constants.acc0)
        let nbOfReceivedNFTs = await subVault.methods.getNbOfNFTReceived().call()
        assert.equal(nbOfReceivedNFTs, 0)
    })
})

async function sendContrFunc(stuffToDo, from){
    let gas = await stuffToDo.estimateGas({from: from})
    return await stuffToDo.send({from: from, gas: gas + 21000, gasPrice: '30000000'})
}

async function deployContract(json, from, web3){
    let contract = await new web3.eth.Contract(json.abi)
    return await sendContrFunc(contract.deploy({data:json.bytecode}), from)
}
