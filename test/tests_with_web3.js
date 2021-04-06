const Greeter = artifacts.require("Greeter");
const SampleNFT = artifacts.require("SampleNFT");
const NFTReceiver = artifacts.require("NFTReceiver");
const constants = require("../constants");

before(async function() {
    accounts = await web3.eth.getAccounts();
});

// Traditional Truffle test
contract("Greeter", accounts => {
    it("Should return the new greeting once it's changed", async function() {
        const greeter = await Greeter.new("Hello, world!");
        assert.equal(await greeter.greet(), "Hello, world!");

        await greeter.setGreeting("Hola, mundo!");

        assert.equal(await greeter.greet(), "Hola, mundo!");
    });
});

contract("SampleNFT", accounts => {
    it("Should create a NFT and give it to me", async function() {
        const sampleNFT = await SampleNFT.new()
        const nftReceiver = await NFTReceiver.new()

        // console.log(sampleNFT.methods)
        await sampleNFT.awardItem(accounts[0])
        let owner = await sampleNFT.ownerOf(12)
        console.log("owner found : " + owner)
        await sampleNFT.safeTransferFrom(accounts[0],nftReceiver.address,12)
        owner = await sampleNFT.ownerOf(12)
        console.log("owner 2 found : " + owner)
    });
});

// Vanilla Mocha test. Increased compatibility with tools that integrate Mocha.
describe("Greeter contract", function() {
    let accounts;

    before(async function() {
        accounts = await web3.eth.getAccounts();
    });

    describe("Deployment", function() {
        it("Should deploy with the right greeting", async function() {
            const greeter = await Greeter.new("Hello, world!");
            assert.equal(await greeter.greet(), "Hello, world!");

            const greeter2 = await Greeter.new("Hola, mundo!");
            assert.equal(await greeter2.greet(), "Hola, mundo!");
        });
    });
});
