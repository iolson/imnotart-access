const Contract = artifacts.require('imnotArtAccess')
const mockErc721 = artifacts.require('mockErc721') // @TODO(iolson): Remove before Deployment to Rinkeby or Mainnet

module.exports = function (deployer, network, accounts) {
    deployer.deploy(Contract);

    if (network == 'development') {
        deployer.deploy(mockErc721);
    }
}