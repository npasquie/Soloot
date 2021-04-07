// const SampleNFT = artifacts.require("SampleNFT")
// const NFTReceiver = artifacts.require("NFTReceiver")
// const sorareABI = require("./sorareABI.json")
// const uniqueManuelCardId = '109885007871154280541989865417424574301301402155804365246179380903455247947907'
// const constants = require("../constants")
// const Web3 = require("web3");
//
// before(async function() {
//     accounts = await web3.eth.getAccounts()
// });
//
// contract("SampleNFT", accounts => {
//     it("Should create a NFT and give it to me then to contract",
//         async function() {
//
//         const sampleNFT = await SampleNFT.new()
//         const nftReceiver = await NFTReceiver.new()
//
//         await sampleNFT.awardItem(accounts[0])
//         let owner = await sampleNFT.ownerOf(12)
//         assert.equal(owner, accounts[0])
//         await sampleNFT.safeTransferFrom(accounts[0],nftReceiver.address,12)
//         assert.equal(await nftReceiver.getNbOfNFTRecived(),1)
//     });
// });
//
// describe("sorare", function (){
//     it("should transfer a sorare card to the receiver contract", async function (){
//         const web32 = await new Web3("https://mainnet.infura.io/v3/7697fcd995504eec91d5e6fd4514aef3")
//         const sorareTokens = await new web32.eth.Contract(sorareABI,constants.sorareTokensAddress)
//         let manuelOwner = await sorareTokens.methods.ownerOf(uniqueManuelCardId).call()
//         console.log(manuelOwner)
//         const sorareTokensSendable = await new web3.eth.Contract(sorareABI,constants.sorareTokensAddress)
//         await web3.eth.sendTransaction({from:accounts[0], to:manuelOwner, value: 76000000000000000000})
//         await hre.network.provider.request({
//             method: "hardhat_impersonateAccount",
//             params: [manuelOwner]})
//         await sorareTokensSendable.methods.safeTransferFrom(manuelOwner,"0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",uniqueManuelCardId).send({from: manuelOwner})
//         manuelOwner = await sorareTokensSendable.methods.ownerOf(uniqueManuelCardId).call()
//         console.log(manuelOwner)
//     })
// })
//
// // const myWeb3 = await new Web3("https://mainnet.infura.io/v3/<myKey>")
// // const sorareTokens = await new myWeb3.eth.Contract(sorareABI,sorareTokensAddress)
// // let manuelOwner = await sorareTokens.methods.ownerOf(uniqueManuelCardId).call()
// // console.log(manuelOwner)
// // // works fine
// //
// // const sorareTokens = await new web3.eth.Contract(sorareABI,sorareTokensAddress)
// // let manuelOwner = await sorareTokens.methods.ownerOf(uniqueManuelCardId).call()
// // // Error: Returned values aren't valid, did it run Out of Gas? You might also (...)
