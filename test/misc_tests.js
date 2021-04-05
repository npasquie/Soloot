const { expect } = require("chai");
const sorareTokensABI = require("./sorareABI.json"); // from etherscan
const constants = require("../constants");
const uniqueManuelCardId = '109885007871154280541989865417424574301301402155804365246179380903455247947907'
const sorareTokensAddress = constants.sorareTokensAddress

describe("Greeter", function() {
  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");

    await greeter.deployed();
    expect(await greeter.greet()).to.equal("Hello, world!");

    await greeter.setGreeting("Hola, mundo!");
    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });

  it("Should read a sorare card metadata", async function () {
    let provider = await new ethers.providers.JsonRpcProvider("http://localhost:8545");
    const sorareTokens = await new ethers.Contract(sorareTokensAddress, sorareTokensABI, provider);

    let club = await sorareTokens.getClub(1);

    expect(club[0]).to.equal('KAS Eupen');
  })

  it("Should transfer the card", async function () {
    const NFTReceiver = await ethers.getContractFactory("NFTReceiver");
    const nftReceiver = await NFTReceiver.deploy();
    await nftReceiver.deployed();
    console.log("NFTReceiver deployed at " + nftReceiver.address)

    let provider = await new ethers.providers.JsonRpcProvider("http://localhost:8545");
    let sorareTokens = await new ethers.Contract(sorareTokensAddress, sorareTokensABI, provider);
    let ownerAddress = await sorareTokens.ownerOf(uniqueManuelCardId);
    let signer = await ethers.provider.getSigner(constants.defaultAccount);
    await signer.sendTransaction({
      to: ownerAddress,
      value: ethers.utils.parseEther("1.0")
    });

    signer = await ethers.provider.getSigner(ownerAddress);
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [ownerAddress]
    })
    sorareTokens = await new ethers.Contract(sorareTokensAddress, sorareTokensABI, signer);

    // weird syntax needed because of ethers js overloading
    await sorareTokens["safeTransferFrom(address,address,uint256)"](ownerAddress, nftReceiver.address, uniqueManuelCardId);

    let nbNFTRecived = await nftReceiver.getNbOfNFTRecived();
    expect(nbNFTRecived).to.equal(1);
  })

  it("should create a sample NFT contract and transfer it", async function () {
    const SampleNFT = await ethers.getContractFactory("SampleNFT");
    const sampleNFT = await SampleNFT.deploy();
    await sampleNFT.deployed();

    let tokenID = await sampleNFT.awardItem(constants.defaultAccount, "http://google.com");
    console.log("tokenID deployed : "+ tokenID.value);

    let uri = await sampleNFT.tokenURI(tokenID.value);
    console.log("found uri : "+ uri);

    const NFTReceiver = await ethers.getContractFactory("NFTReceiver");
    const nftReceiver = await NFTReceiver.deploy();
    await nftReceiver.deployed();

    //let signer = await ethers.provider.getSigner(constants.defaultAccount);
    await sampleNFT["safeTransferFrom(address,address,uint256)"](constants.defaultAccount, nftReceiver.address, tokenID.value);
    // non existing token ??

    let nbNFTRecived = await nftReceiver.getNbOfNFTRecived();
    expect(nbNFTRecived).to.equal(1);
  })
})
