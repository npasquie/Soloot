const myWeb3 = require("web3");
const constants = require("../constants")
const sorareABI = require("./sorareABI.json")
const uniqueManuelCardId = '109885007871154280541989865417424574301301402155804365246179380903455247947907'

describe("sorare", function (){
    it("should transfer a sorare card to the receiver contract", async function (){
        const myweb3 = new myWeb3("http://localhost:8545")
        accounts = await myweb3.eth.getAccounts()
        const sorareTokens = await new myweb3.eth.Contract(sorareABI,constants.sorareTokensAddress)
        let manuelOwner = await sorareTokens.methods.ownerOf(uniqueManuelCardId).call()
        console.log(manuelOwner)
    })
})
