const myWeb3 = require("web3");
const constants = require("../constants")
const sorareABI = require("./sorareABI.json")
const nftReceiverJson = require("../artifacts/contracts/NFTReceiver.sol/NFTReceiver.json")
const assert = require('assert');
// const ganache = require("ganache-core");
// const NFTReceiver = artifacts.require("NFTReceiver")
const uniqueManuelCardId = '109885007871154280541989865417424574301301402155804365246179380903455247947907'

describe("sorare test suite", function (){
    this.timeout(10000);

    let myweb3;
    let accounts;
    let sorareTokens;

    before(async function (){
        myweb3 = new myWeb3("http://localhost:8545")
        accounts = await myweb3.eth.getAccounts()
        sorareTokens = await new myweb3.eth.Contract(sorareABI,constants.sorareTokensAddress)
    })

    it("should transfer a sorare card to another account", async function (){
        await myweb3.eth.sendTransaction({
            from: constants.acc0,
            to: constants.manuelCardHolderAddress,
            value: '1000000000000000000' // 1 ETH
        })
        let gas = await sorareTokens.methods.safeTransferFrom(constants.manuelCardHolderAddress,constants.acc0,uniqueManuelCardId).estimateGas({from:constants.manuelCardHolderAddress})
        await sorareTokens.methods.safeTransferFrom(constants.manuelCardHolderAddress,constants.acc0,uniqueManuelCardId).send({from:constants.manuelCardHolderAddress, gas: gas + 21000,gasPrice:'30000000'})
        let newOwner = await sorareTokens.methods.ownerOf(uniqueManuelCardId).call()
        assert.equal(newOwner,constants.acc0)
    })

    it("should transfer the card from an user to the receiver contract", async function (){
        let nftReceiver = await new myweb3.eth.Contract(nftReceiverJson.abi)
        let gas =  await nftReceiver.deploy({data: nftReceiverJson.bytecode}).estimateGas({from: constants.acc0})
        nftReceiver = await nftReceiver.deploy({data: nftReceiverJson.bytecode})
            .send({
                from: constants.acc0,
                gas: gas + 21000,
                gasPrice:'30000000'})
        let contrAddress = nftReceiver.options.address
        // console.log(contrAddress)

        gas = await sorareTokens.methods.safeTransferFrom(constants.acc0,contrAddress,uniqueManuelCardId).estimateGas({from:constants.acc0})
        await sorareTokens.methods.safeTransferFrom(constants.acc0,contrAddress,uniqueManuelCardId).send({from:constants.acc0, gas: gas + 21000, gasPrice:'30000000'})
        let nbOfReceivedNFTs = await nftReceiver.methods.getNbOfNFTReceived().call()
        // console.log(nbOfReceivedNFTs)
        assert.equal(nbOfReceivedNFTs, 1)
    })
})
