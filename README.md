## Launch local test chain
` npx hardhat node --fork https://mainnet.infura.io/v3/<your key>`  
fork of the ethereum mainnet  
Contracts are auto compiled and deployed on launch

## Compile
`npx hardhat compile`

## Deploy
`npx hardhat --network localhost deploy`

## Test
`npx hardhat test --deploy-fixture`

## Notes
use yarn
