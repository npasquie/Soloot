const { expect } = require("chai");
const sorareTokensJson = require("../artifacts/contracts/lib/SorareTokens.sol/SorareTokens.json");

describe("Greeter", function() {
  it("Should return the new greeting once it's changed", async function() {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");
    
    await greeter.deployed();
    expect(await greeter.greet()).to.equal("Hello, world!");

    await greeter.setGreeting("Hola, mundo!");
    expect(await greeter.greet()).to.equal("Hola, mundo!");
  });

  it("Should read a sorare card metadata", async function () {
    const sorareTokensAddress= "0x629A673A8242c2AC4B7B8C5D8735fbeac21A6205";
    let provider = ethers.getDefaultProvider();
    const sorareTokens = await new ethers.Contract(sorareTokensAddress,sorareTokensJson.abi, provider);

    await sorareTokens.getClub(1).then(console.log);

    expect(true).to.be.true;
  });
});
