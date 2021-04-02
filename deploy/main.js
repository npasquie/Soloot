module.exports = async ({
        getNamedAccounts,
        deployments,
        getChainId,
        getUnnamedAccounts,
    }) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();

    await deploy('Greeter', {
        from: deployer,
        gasLimit: 4000000,
        args: ['hello'],
        deterministicDeployment: true
    });
    await deploy('NFTReceiver', {
        from: deployer,
        gasLimit: 4000000,
        args: [],
        deterministicDeployment: true
    });
};
